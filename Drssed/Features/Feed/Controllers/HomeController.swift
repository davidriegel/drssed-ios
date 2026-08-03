//
//  HomeController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

/// Home screen of the app: the outfits that suit today's weather on top, below them the
/// month grid of everything that was worn.
///
/// The grid is a log that only ever grows – entries appear by wearing an outfit and are
/// not edited or removed from here, which is why a day opens read-only.
public class HomeController: UIViewController {
    private let wearRepo: WearRepository = AppRepository.shared.wearRepository
    private let outfitRepo: OutfitRepository = AppRepository.shared.outfitRepository
    private let calendar: Calendar = .current

    private lazy var recommendationSession = OutfitRecommendationSession()

    /// Any date inside the month that is currently shown.
    private var anchorDate: Date = Date() {
        didSet { Task { await reloadMonth() } }
    }

    private var days: [WearCalendarDay] = [] {
        didSet {
            // A month spans five or six rows, which changes how tall the grid is.
            calendarHeightConstraint?.constant = calendarHeight
            calendarCollectionView.collectionViewLayout.invalidateLayout()
            calendarCollectionView.reloadData()
            updateMonthLabels()
        }
    }

    private var recommendations: [Outfit] = [] {
        didSet {
            recommendationCollectionView.reloadData()
            updateRecommendationState()
        }
    }

    /// Outfits that already carry an entry for today, so the shortcut cannot log them twice.
    private var wornTodayOutfitIDs: Set<String> = []

    /// The weather the current recommendations are based on.
    private var weather: WeatherSnapshot? {
        didSet { updateWeatherLabel() }
    }

    /// Why there is nothing to suggest – each case needs its own wording, and some of them
    /// a way out.
    private enum RecommendationGap {
        case offline
        case locationDenied
        case weatherUnavailable
        case noOutfits
        case noMatch
    }

    private var recommendationGap: RecommendationGap = .noMatch

    /// When the suggestions last came in, so that they do not keep describing this morning's
    /// weather after the app has been in the background all day.
    private var lastRecommendationLoad: Date?

    private static let recommendationStaleAfter: TimeInterval = 30 * 60

    private var recommendationHeightConstraint: NSLayoutConstraint?

    private var calendarHeightConstraint: NSLayoutConstraint?

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()

        Task { await reloadMonth() }
        Task { await reloadRecommendations() }

        NotificationCenter.default.addObserver(self, selector: #selector(onWearsChanged), name: .syncDidFinish, object: nil)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateGreeting()

        Task { await reloadMonth() }

        // The suggestions stay put while they are still current; once they describe weather
        // from hours ago they are fetched again rather than quietly going stale.
        if let lastLoad = lastRecommendationLoad, Date().timeIntervalSince(lastLoad) < Self.recommendationStaleAfter {
            Task { await refreshWornToday() }
        } else {
            Task { await reloadRecommendations() }
        }
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The cards scale with the width of the screen, which is only final once laid out.
        if recommendationHeightConstraint?.constant != recommendationSectionHeight {
            recommendationHeightConstraint?.constant = recommendationSectionHeight
            recommendationCollectionView.collectionViewLayout.invalidateLayout()
            centerRecommendations()
        }

        // The rows scale with the width of the screen, so the grid is only measurable now.
        if calendarHeightConstraint?.constant != calendarHeight {
            calendarHeightConstraint?.constant = calendarHeight
            calendarCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    // MARK: - UI Elements -

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addAction(UIAction { [weak self] _ in
            self?.handleRefresh()
        }, for: .valueChanged)
        return rc
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.alwaysBounceVertical = true
        sv.showsVerticalScrollIndicator = true
        sv.backgroundColor = .background
        sv.refreshControl = refreshControl
        return sv
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var recommendationTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .black)
        label.textColor = .label
        label.text = String(localized: "home.recommendations.title")
        return label
    }()

    private lazy var recommendationWeatherLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    /// Apple requires the trademark and a link to the legal page wherever WeatherKit data shows up.
    private lazy var weatherAttributionButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { _ in
            guard let url = URL(string: "https://weatherkit.apple.com/legal-attribution.html") else { return }
            UIApplication.shared.open(url)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle("\u{F8FF} Weather", for: .normal)
        bt.titleLabel?.font = .systemFont(ofSize: 11, weight: .medium)
        bt.setTitleColor(.tertiaryLabel, for: .normal)
        bt.isHidden = true
        return bt
    }()

    private lazy var recommendationSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        spinner.color = .secondaryLabel
        return spinner
    }()

    private lazy var recommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Self.recommendationSpacing
        layout.minimumInteritemSpacing = Self.recommendationSpacing

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(OutfitRecommendationCell.self, forCellWithReuseIdentifier: OutfitRecommendationCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = false
        cv.backgroundColor = .background
        return cv
    }()

    private lazy var recommendationEmptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    /// Shown only for the gaps the user can actually close.
    private lazy var recommendationActionButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { _ in
            self.didTapRecommendationAction()
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.titleLabel?.font = .systemFont(ofSize: 13, weight: .heavy)
        bt.setTitleColor(.accent, for: .normal)
        return bt
    }()

    private lazy var recommendationEmptyStack: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [recommendationEmptyLabel, recommendationActionButton])
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .vertical
        sv.alignment = .center
        sv.spacing = 6
        sv.isHidden = true
        return sv
    }()

    private lazy var historyTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .black)
        label.textColor = .label
        label.text = String(localized: "home.history.title")
        return label
    }()

    private lazy var monthSummaryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var previousMonthButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { _ in
            self.moveMonth(by: -1)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), for: .normal)
        bt.tintColor = .accent
        bt.accessibilityLabel = String(localized: "calendar.month.previous")
        return bt
    }()

    private lazy var nextMonthButton: UIButton = {
        let bt = UIButton(type: .system, primaryAction: UIAction { _ in
            self.moveMonth(by: 1)
        })
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)), for: .normal)
        bt.tintColor = .accent
        bt.accessibilityLabel = String(localized: "calendar.month.next")
        return bt
    }()

    private lazy var todayButton: UIBarButtonItem = {
        UIBarButtonItem(title: String(localized: "calendar.today"), primaryAction: UIAction { _ in
            self.anchorDate = Date()
        })
    }()

    private lazy var weekdayStack: UIStackView = {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let ordered = (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }

        let labels: [UILabel] = ordered.map { symbol in
            let label = UILabel()
            label.text = symbol.uppercased()
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 10, weight: .heavy)
            label.textColor = .tertiaryLabel
            return label
        }

        let sv = UIStackView(arrangedSubviews: labels)
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        return sv
    }()

    private lazy var calendarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(WearCalendarDayCell.self, forCellWithReuseIdentifier: WearCalendarDayCell.identifier)
        cv.dataSource = self
        cv.delegate = self
        cv.isScrollEnabled = false
        cv.backgroundColor = .background
        return cv
    }()

    // MARK: - Recommendations -

    /// Fetches the suggestions for the current weather.
    ///
    /// Errors stay quiet here because this also runs unprompted when the screen opens.
    private func reloadRecommendations() async {
        let snapshot = await WeatherProvider.shared.currentWeather()

        await MainActor.run { self.weather = snapshot }

        guard let snapshot else {
            let gap: RecommendationGap = await MainActor.run {
                if LocationProvider.shared.isDenied { return .locationDenied }
                return NetworkManager.shared.isReachable ? .weatherUnavailable : .offline
            }

            await MainActor.run {
                self.recommendationGap = gap
                self.recommendations = []
            }
            return
        }

        await refreshWornToday()

        do {
            let page = try await recommendationSession.nextPage(feelsLike: snapshot.feelsLike)

            // Nothing came back: either the wardrobe is empty or nothing suits the weather.
            var gap: RecommendationGap = .noMatch
            if page.isEmpty, await outfitRepo.fetchOutfits().isEmpty {
                gap = .noOutfits
            }

            await MainActor.run {
                self.recommendationGap = gap
                self.recommendations = page
                self.lastRecommendationLoad = Date()
            }
        } catch {
            ErrorHandler.handleSilently(error)

            let isReachable = NetworkManager.shared.isReachable

            await MainActor.run {
                self.recommendationGap = isReachable ? .noMatch : .offline
                self.recommendations = []
            }
        }
    }

    /// Pull to refresh brings the whole screen up to date: the log from the server and a
    /// fresh set of suggestions, rather than only what happens to be stale.
    private func handleRefresh() {
        Task {
            await SyncManager.shared.syncWithServer()
            await reloadMonth()
            await reloadRecommendations()

            refreshControl.endRefreshing()
        }
    }

    private func refreshWornToday() async {
        let startOfToday = calendar.startOfDay(for: Date())

        guard let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return }

        let wears = await wearRepo.fetchWears(from: startOfToday, to: startOfTomorrow)
        let outfitIDs = Set(wears.map(\.outfitID))

        await MainActor.run {
            guard self.wornTodayOutfitIDs != outfitIDs else { return }

            self.wornTodayOutfitIDs = outfitIDs
            self.recommendationCollectionView.reloadData()
        }
    }

    /// Logs a suggestion as worn right now, weather included, without asking for details.
    private func wearRecommendation(_ outfit: Outfit) async {
        guard let logged = await wearRepo.logWearNow(outfitID: outfit.id) else { return }

        await MainActor.run {
            self.wornTodayOutfitIDs.insert(logged.outfitID)
            self.recommendationCollectionView.reloadData()

            ToastPresenter.success(String(format: NSLocalizedString("home.recommendations.worn", comment: ""), outfit.name))
        }

        await reloadMonth()
    }

    private func openOutfit(with outfitID: String) {
        Task {
            guard let outfit = await outfitRepo.getOutfit(with: outfitID) else { return }

            await MainActor.run { self.presentOutfitDetails(for: outfit) }
        }
    }

    /// Lets the user pick which of the day's outfits to look at. Wearing more than one
    /// outfit a day is rare, so this stays a sheet instead of a permanent list.
    private func presentWearPicker(for day: WearCalendarDay) {
        let sheet = UIAlertController(
            title: day.date?.formatted(date: .long, time: .omitted),
            message: nil,
            preferredStyle: .actionSheet
        )

        for wear in day.wears {
            let title = wear.outfitName ?? String(localized: "calendar.outfit.unknown")

            sheet.addAction(UIAlertAction(title: title, style: .default) { _ in
                self.openOutfit(with: wear.outfitID)
            })
        }

        sheet.addAction(UIAlertAction(title: String(localized: "common.cancel"), style: .cancel))

        present(sheet, animated: true)
    }

    /// Opens an outfit for viewing only – nothing on this screen edits an outfit or a wear.
    private func presentOutfitDetails(for outfit: Outfit) {
        let detailsController = OutfitDetailsController(outfit: outfit, isReadOnly: true)

        let navController = UINavigationController(rootViewController: detailsController)
        navController.setNavigationBarHidden(true, animated: false)

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }

        navigationController?.present(navController, animated: true)
    }

    private func updateRecommendationState() {
        let isEmpty = recommendations.isEmpty

        recommendationCollectionView.isHidden = isEmpty
        recommendationEmptyStack.isHidden = !isEmpty

        switch recommendationGap {
        case .offline:
            recommendationEmptyLabel.text = String(localized: "home.recommendations.empty.offline")
            recommendationActionButton.setTitle(nil, for: .normal)
        case .locationDenied:
            recommendationEmptyLabel.text = String(localized: "home.recommendations.empty.location")
            recommendationActionButton.setTitle(String(localized: "home.recommendations.action.settings"), for: .normal)
        case .weatherUnavailable:
            recommendationEmptyLabel.text = String(localized: "home.recommendations.empty.weather")
            recommendationActionButton.setTitle(nil, for: .normal)
        case .noOutfits:
            recommendationEmptyLabel.text = String(localized: "home.recommendations.empty.noOutfits")
            recommendationActionButton.setTitle(String(localized: "home.recommendations.action.createOutfit"), for: .normal)
        case .noMatch:
            recommendationEmptyLabel.text = String(localized: "home.recommendations.empty")
            recommendationActionButton.setTitle(nil, for: .normal)
        }

        recommendationActionButton.isHidden = recommendationActionButton.title(for: .normal) == nil

        recommendationHeightConstraint?.constant = recommendationSectionHeight
        recommendationCollectionView.collectionViewLayout.invalidateLayout()
        centerRecommendations()
    }

    private func didTapRecommendationAction() {
        switch recommendationGap {
        case .locationDenied:
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        case .noOutfits:
            // The lookbook is where an outfit gets put together.
            tabBarController?.selectedIndex = 2
        default:
            break
        }
    }

    /// Keeps the row centred when it does not fill the width, instead of letting a lone
    /// card cling to the left edge.
    private func centerRecommendations() {
        guard !recommendations.isEmpty else {
            recommendationCollectionView.contentInset = .zero
            return
        }

        let count = CGFloat(recommendations.count)
        let contentWidth = count * recommendationCellWidth + (count - 1) * Self.recommendationSpacing
        let inset = max(0, (recommendationCollectionView.bounds.width - contentWidth) / 2)

        recommendationCollectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }

    private func updateWeatherLabel() {
        guard let weather else {
            recommendationWeatherLabel.text = String(localized: "home.recommendations.weather.unavailable")
            weatherAttributionButton.isHidden = true
            return
        }

        let feelsLike = NumberFormatter.localizedString(from: NSNumber(value: weather.feelsLike), number: .decimal)

        recommendationWeatherLabel.text = String(
            format: NSLocalizedString("home.recommendations.weather", comment: ""),
            feelsLike,
            weather.condition.localizedName
        )
        weatherAttributionButton.isHidden = false
    }

    // MARK: - Data -

    private func reloadMonth() async {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: anchorDate)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return }

        let wears = await wearRepo.fetchWears(from: monthStart, to: monthEnd)
        let days = WearCalendarDay.month(for: anchorDate, wears: wears, calendar: calendar)

        await MainActor.run { self.days = days }
    }

    @objc private func onWearsChanged() {
        Task {
            await reloadMonth()
            await refreshWornToday()
        }
    }

    private func moveMonth(by months: Int) {
        guard let moved = calendar.date(byAdding: .month, value: months, to: anchorDate) else { return }
        anchorDate = moved
    }

    private func updateMonthLabels() {
        let month = anchorDate.formatted(.dateTime.month(.wide).year())
        let entries = days.reduce(0) { $0 + $1.wears.count }
        let entriesText = String(format: NSLocalizedString("calendar.month.entries", comment: ""), entries)

        monthSummaryLabel.text = "\(month) · \(entriesText)"
    }

    /// The navigation title greets by time of day, so the screen reads as a home rather than
    /// as a calendar.
    ///
    /// This sets `navigationItem.title` rather than `title`, which would also relabel the
    /// tab bar item – the tabs carry icons only.
    private func updateGreeting() {
        let key: String.LocalizationValue

        switch calendar.component(.hour, from: Date()) {
        case 5..<11: key = "home.greeting.morning"
        case 11..<17: key = "home.greeting.day"
        case 17..<22: key = "home.greeting.evening"
        default: key = "home.greeting.night"
        }

        navigationItem.title = String(localized: key)
    }

    private var dayCellWidth: CGFloat {
        return (view.bounds.width - 2 * Self.gridMargin) / 7
    }

    private var dayCellHeight: CGFloat {
        return dayCellWidth * 4.0 / 3.0
    }

    /// The grid does not scroll on its own – it is as tall as its rows need, and the screen
    /// around it scrolls instead.
    private var calendarHeight: CGFloat {
        return CGFloat(max(1, days.count / 7)) * dayCellHeight
    }

    /// The grid sits closer to the edges than the rest of the screen: every point of width
    /// goes into the outfit thumbnails, which are what makes a day recognisable.
    private static let gridMargin: CGFloat = 10

    private static let recommendationSpacing: CGFloat = 4

    /// Fewer than three suggestions share the row between them instead of leaving the rest
    /// of the width blank. A single one keeps the width of two, so it stays a card rather
    /// than turning into a banner.
    private var recommendationColumns: CGFloat {
        return CGFloat(min(3, max(2, recommendations.count)))
    }

    private var recommendationCellWidth: CGFloat {
        let available = view.bounds.width - 40 - Self.recommendationSpacing * (recommendationColumns - 1)
        return available / recommendationColumns
    }

    /// Capped so that a wider card does not push the month grid past the bottom of the screen.
    private var recommendationCellHeight: CGFloat {
        return min(recommendationCellWidth * 1.2, 152)
    }

    /// While there is nothing to suggest the strip collapses to the height of its notice,
    /// so that the log moves up instead of leaving a hole. A notice that offers a way out
    /// needs the extra line for its button.
    private var recommendationSectionHeight: CGFloat {
        guard recommendations.isEmpty else { return recommendationCellHeight }

        return recommendationActionButton.isHidden ? 52 : 82
    }

    // MARK: - Layout -

    private func configureViewComponents() {
        view.backgroundColor = .background

        updateGreeting()

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = todayButton

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        [recommendationTitleLabel, recommendationWeatherLabel, weatherAttributionButton, recommendationSpinner, recommendationCollectionView, recommendationEmptyStack, historyTitleLabel, monthSummaryLabel, previousMonthButton, nextMonthButton, weekdayStack, calendarCollectionView].forEach { contentView.addSubview($0) }

        let recommendationHeight = recommendationCollectionView.heightAnchor.constraint(equalToConstant: recommendationCellHeight)
        recommendationHeightConstraint = recommendationHeight

        let calendarHeight = calendarCollectionView.heightAnchor.constraint(equalToConstant: self.calendarHeight)
        calendarHeightConstraint = calendarHeight

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            recommendationTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            recommendationTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            recommendationSpinner.centerYAnchor.constraint(equalTo: recommendationTitleLabel.centerYAnchor),
            recommendationSpinner.leadingAnchor.constraint(greaterThanOrEqualTo: recommendationTitleLabel.trailingAnchor, constant: 10),
            recommendationSpinner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            recommendationWeatherLabel.topAnchor.constraint(equalTo: recommendationTitleLabel.bottomAnchor, constant: 2),
            recommendationWeatherLabel.leadingAnchor.constraint(equalTo: recommendationTitleLabel.leadingAnchor),

            weatherAttributionButton.centerYAnchor.constraint(equalTo: recommendationWeatherLabel.centerYAnchor),
            weatherAttributionButton.leadingAnchor.constraint(greaterThanOrEqualTo: recommendationWeatherLabel.trailingAnchor, constant: 10),
            weatherAttributionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            recommendationCollectionView.topAnchor.constraint(equalTo: recommendationWeatherLabel.bottomAnchor, constant: 8),
            recommendationCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendationCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            recommendationHeight,

            recommendationEmptyStack.topAnchor.constraint(equalTo: recommendationCollectionView.topAnchor, constant: 10),
            recommendationEmptyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            recommendationEmptyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            historyTitleLabel.topAnchor.constraint(equalTo: recommendationCollectionView.bottomAnchor, constant: 18),
            historyTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            nextMonthButton.centerYAnchor.constraint(equalTo: historyTitleLabel.centerYAnchor),
            nextMonthButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 44),

            previousMonthButton.centerYAnchor.constraint(equalTo: historyTitleLabel.centerYAnchor),
            previousMonthButton.trailingAnchor.constraint(equalTo: nextMonthButton.leadingAnchor),
            previousMonthButton.widthAnchor.constraint(equalToConstant: 44),

            monthSummaryLabel.topAnchor.constraint(equalTo: historyTitleLabel.bottomAnchor, constant: 2),
            monthSummaryLabel.leadingAnchor.constraint(equalTo: historyTitleLabel.leadingAnchor),
            monthSummaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: previousMonthButton.leadingAnchor, constant: -10),

            weekdayStack.topAnchor.constraint(equalTo: monthSummaryLabel.bottomAnchor, constant: 12),
            weekdayStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.gridMargin),
            weekdayStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.gridMargin),

            calendarCollectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 6),
            calendarCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.gridMargin),
            calendarCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.gridMargin),
            calendarHeight,
            calendarCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        addMonthSwipeGestures()
        updateWeatherLabel()
        updateRecommendationState()
    }

    /// Swiping the grid moves to the previous or next month.
    private func addMonthSwipeGestures() {
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipedLeft))
        left.direction = .left

        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipedRight))
        right.direction = .right

        calendarCollectionView.addGestureRecognizer(left)
        calendarCollectionView.addGestureRecognizer(right)
    }

    @objc
    private func swipedLeft() {
        moveMonth(by: 1)
    }

    @objc
    private func swipedRight() {
        moveMonth(by: -1)
    }
}

// MARK: - Suggestions and wear log

extension HomeController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView === recommendationCollectionView {
            return recommendations.count
        }

        return days.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === recommendationCollectionView {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: OutfitRecommendationCell.identifier,
                for: indexPath
            ) as! OutfitRecommendationCell

            let outfit = recommendations[indexPath.item]
            cell.configure(with: outfit, isWornToday: wornTodayOutfitIDs.contains(outfit.id))
            cell.onWear = { [weak self] in
                Task { await self?.wearRecommendation(outfit) }
            }

            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WearCalendarDayCell.identifier,
            for: indexPath
        ) as! WearCalendarDayCell

        cell.configure(day: days[indexPath.item])

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === recommendationCollectionView {
            return CGSize(width: recommendationCellWidth, height: recommendationCellHeight)
        }

        return CGSize(width: dayCellWidth, height: dayCellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView === recommendationCollectionView {
            presentOutfitDetails(for: recommendations[indexPath.item])
            return
        }

        // A day of the log shows what was worn on it, nothing more.
        let day = days[indexPath.item]

        guard let first = day.wears.first else { return }

        // The grid badges a day that carries several outfits, so all of them have to be
        // reachable – otherwise the badge promises something the screen cannot deliver.
        guard day.wears.count == 1 else {
            presentWearPicker(for: day)
            return
        }

        openOutfit(with: first.outfitID)
    }
}
