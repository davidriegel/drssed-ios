//
//  HomeController.swift
//  Outfitter
//
//  Created by David Riegel on 06.05.24.
//

import UIKit

/// Calendar of the logged wears: a month grid of the worn outfits with the
/// entries of the selected day listed below.
public class HomeController: UIViewController {
    private let wearRepo: WearRepository = AppRepository.shared.wearRepository
    private let calendar: Calendar = .current

    /// Any date inside the month that is currently shown.
    private var anchorDate: Date = Date() {
        didSet { Task { await reloadMonth() } }
    }

    private var selectedDate: Date {
        didSet {
            updateSelectedDay()
            calendarCollectionView.reloadData()
        }
    }

    private var days: [WearCalendarDay] = [] {
        didSet {
            calendarHeightConstraint?.constant = gridHeight(forRows: days.count / 7)
            calendarCollectionView.reloadData()
            updateMonthLabels()
            updateSelectedDay()
        }
    }

    private var selectedDayWears: [OutfitWear] = [] {
        didSet {
            dayLogTableView.reloadData()
            emptyDayLabel.isHidden = !selectedDayWears.isEmpty
        }
    }

    private var calendarHeightConstraint: NSLayoutConstraint?

    public init() {
        self.selectedDate = Calendar.current.startOfDay(for: Date())

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        configureViewComponents()

        Task { await reloadMonth() }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task { await reloadMonth() }
    }

    // MARK: - UI Elements -

    private lazy var monthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .black)
        label.textColor = .label
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
            self.selectedDate = self.calendar.startOfDay(for: Date())
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

    private lazy var selectedDayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .black)
        label.textColor = .label
        return label
    }()

    private lazy var emptyDayLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(localized: "calendar.day.empty")
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()

    private lazy var dayLogTableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(WearLogCell.self, forCellReuseIdentifier: WearLogCell.identifier)
        tv.dataSource = self
        tv.delegate = self
        tv.backgroundColor = .background
        tv.separatorStyle = .none
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 74
        tv.refreshControl = refreshControl
        return tv
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addAction(UIAction { _ in
            Task {
                await SyncManager.shared.syncWithServer()
                await self.reloadMonth()

                await MainActor.run { rc.endRefreshing() }
            }
        }, for: .valueChanged)
        return rc
    }()

    // MARK: - Data -

    private func reloadMonth() async {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: anchorDate)),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { return }

        let wears = await wearRepo.fetchWears(from: monthStart, to: monthEnd)
        let days = WearCalendarDay.month(for: anchorDate, wears: wears, calendar: calendar)

        await MainActor.run {
            self.days = days

            // Keep the selection inside the month that is on screen.
            if !days.contains(where: { $0.date == self.selectedDate }),
               let firstOfMonth = days.first(where: { $0.date != nil })?.date {
                self.selectedDate = firstOfMonth
            }
        }
    }

    private func moveMonth(by months: Int) {
        guard let moved = calendar.date(byAdding: .month, value: months, to: anchorDate) else { return }
        anchorDate = moved
    }

    private func updateSelectedDay() {
        selectedDayLabel.text = selectedDate.formatted(date: .complete, time: .omitted)
        selectedDayWears = days.first { $0.date == selectedDate }?.wears ?? []
    }

    private func updateMonthLabels() {
        monthLabel.text = anchorDate.formatted(.dateTime.month(.wide).year())

        let entries = days.reduce(0) { $0 + $1.wears.count }
        monthSummaryLabel.text = String(format: NSLocalizedString("calendar.month.entries", comment: ""), entries)
    }

    private func gridHeight(forRows rows: Int) -> CGFloat {
        return CGFloat(max(rows, 1)) * dayCellHeight
    }

    private var dayCellWidth: CGFloat {
        return (view.bounds.width - 40) / 7
    }

    private var dayCellHeight: CGFloat {
        return dayCellWidth * 4.0 / 3.0
    }

    private func presentWearEditor(for wear: OutfitWear) {
        let editor = WearEditorController(mode: .edit(wear))
        editor.delegate = self

        let navController = UINavigationController(rootViewController: editor)
        navController.setNavigationBarHidden(true, animated: false)

        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(navController, animated: true)
    }

    // MARK: - Layout -

    private func configureViewComponents() {
        view.backgroundColor = .background
        title = String(localized: "calendar.title")

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .black)]
        navigationController?.navigationBar.titleTextAttributes = titleAttributes

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = todayButton

        [monthLabel, monthSummaryLabel, previousMonthButton, nextMonthButton, weekdayStack, calendarCollectionView, selectedDayLabel, dayLogTableView, emptyDayLabel].forEach { view.addSubview($0) }

        let calendarHeight = calendarCollectionView.heightAnchor.constraint(equalToConstant: gridHeight(forRows: 6))
        calendarHeightConstraint = calendarHeight

        NSLayoutConstraint.activate([
            monthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            monthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            monthSummaryLabel.topAnchor.constraint(equalTo: monthLabel.bottomAnchor, constant: 2),
            monthSummaryLabel.leadingAnchor.constraint(equalTo: monthLabel.leadingAnchor),

            nextMonthButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            nextMonthButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextMonthButton.widthAnchor.constraint(equalToConstant: 44),

            previousMonthButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            previousMonthButton.trailingAnchor.constraint(equalTo: nextMonthButton.leadingAnchor),
            previousMonthButton.widthAnchor.constraint(equalToConstant: 44),

            weekdayStack.topAnchor.constraint(equalTo: monthSummaryLabel.bottomAnchor, constant: 12),
            weekdayStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            weekdayStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            calendarCollectionView.topAnchor.constraint(equalTo: weekdayStack.bottomAnchor, constant: 6),
            calendarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            calendarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarHeight,

            selectedDayLabel.topAnchor.constraint(equalTo: calendarCollectionView.bottomAnchor, constant: 14),
            selectedDayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectedDayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            dayLogTableView.topAnchor.constraint(equalTo: selectedDayLabel.bottomAnchor, constant: 8),
            dayLogTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayLogTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayLogTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            emptyDayLabel.topAnchor.constraint(equalTo: dayLogTableView.topAnchor, constant: 20),
            emptyDayLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyDayLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        addMonthSwipeGestures()
        updateSelectedDay()
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

// MARK: - Calendar grid

extension HomeController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return days.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: WearCalendarDayCell.identifier,
            for: indexPath
        ) as! WearCalendarDayCell

        let day = days[indexPath.item]
        cell.configure(day: day, isSelected: day.date == selectedDate)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: dayCellWidth, height: dayCellHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let date = days[indexPath.item].date else { return }
        selectedDate = date
    }
}

// MARK: - Entries of the selected day

extension HomeController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selectedDayWears.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WearLogCell.identifier, for: indexPath) as! WearLogCell
        cell.configure(with: selectedDayWears[indexPath.row])
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presentWearEditor(for: selectedDayWears[indexPath.row])
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let wear = selectedDayWears[indexPath.row]

        let delete = UIContextualAction(style: .destructive, title: String(localized: "common.delete")) { _, _, completion in
            Task {
                let deleted = await self.wearRepo.deleteWear(with: wear.id)

                if deleted {
                    await self.reloadMonth()
                }

                await MainActor.run { completion(deleted) }
            }
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Wear editor

extension HomeController: WearEditorDelegate {
    func wearEditor(_ controller: WearEditorController, didSave wear: OutfitWear) {
        Task { await reloadMonth() }
    }

    func wearEditor(_ controller: WearEditorController, didDelete wearID: String) {
        Task { await reloadMonth() }
    }
}
