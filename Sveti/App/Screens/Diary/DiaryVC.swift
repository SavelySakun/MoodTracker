import UIKit

class DiaryVC: BaseViewController {

  private let emptyView = ImageTextView(imageName: "2cats", text: "Add the first note in the \"New note\" section")
  private let arrowImageView = UIImageView()
  private let tableView = UITableView()
  private let viewModel = DiaryVM()

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.updateContent()
  }

  override func logOpenScreenEvent() {
    SvetiAnalytics.log(.Diary)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setLayout()
  }

  override func updateContent() {
    DispatchQueue.main.async { [self] in
      viewModel.loadNotes()
      updateEmptyViewVisibility()
      tableView.reloadData()
    }
  }

  private func setLayout() {
    title = "Diary"
    setTable()
    setEmptyView()
    setArrowToNewNoteTapBar()
    view.backgroundColor = .systemGray6
  }

  private func setTable() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(DiaryCell.self, forCellReuseIdentifier: "DiaryCell")
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemGray6

    view.addSubview(tableView)
    tableView.snp.makeConstraints { (make) in
      make.top.left.bottom.right.equalToSuperview()
    }
  }

  private func setEmptyView() {
    view.addSubview(emptyView)
    updateEmptyViewVisibility()
    emptyView.snp.makeConstraints { (make) in
      make.height.equalToSuperview().multipliedBy(0.4)
      make.width.equalToSuperview().multipliedBy(0.7)
      make.centerX.centerY.equalToSuperview()
    }
  }

  private func updateEmptyViewVisibility() {
    let isHidden = !viewModel.sectionsWithNotes.isEmpty
    emptyView.isHidden = isHidden
    arrowImageView.isHidden = isHidden
  }

  private func setArrowToNewNoteTapBar() {
    arrowImageView.image = UIImage(named: "arrow")?.withRenderingMode(.alwaysTemplate)
    arrowImageView.tintColor = .systemBlue
    view.addSubview(arrowImageView)
    arrowImageView.snp.makeConstraints { (make) in
      make.left.equalToSuperview().offset(calculateOffsetForArrow())
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
      make.height.equalTo(100)
      make.width.equalTo(20)
    }
  }

  private func calculateOffsetForArrow() -> CGFloat {
    let tabbarButtonItems = orderedTabBarItemViews()
    let diaryItem = tabbarButtonItems[0]
    let maxXoffsetToButton = diaryItem.frame.maxX
    let minXoffsetToButton = diaryItem.frame.minX
    let correctOffsetToCenter = (0.45 * (maxXoffsetToButton - minXoffsetToButton)) + maxXoffsetToButton
    return correctOffsetToCenter
  }

  private func orderedTabBarItemViews() -> [UIView] {
    guard let tabbar = tabBarController?.tabBar else { return [] }
    let interactionViews = tabbar.subviews.filter { $0.isUserInteractionEnabled }
    return interactionViews.sorted(by: { $0.frame.minX < $1.frame.minX })
  }
}

extension DiaryVC: UITableViewDelegate {

}

extension DiaryVC: UITableViewDataSource {

  func numberOfSections(in tableView: UITableView) -> Int {
    viewModel.sectionsWithNotes.count
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.sectionsWithNotes[section].notes.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "DiaryCell", for: indexPath) as? DiaryCell else { return UITableViewCell() }
    let note = viewModel.sectionsWithNotes[indexPath.section].notes[indexPath.row]
    cell.configure(with: note)
    cell.layoutIfNeeded()
    return cell
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return getDiaryTableSectionHeader(for: section)
  }

  private func getDiaryTableSectionHeader(for section: Int) -> DiaryTableSectionHeader {

    var isSameYear = false // If current & previous section item have the same date -> don't show year string in the current section title.
    let sectionItem = viewModel.sectionsWithNotes[section]

    if let nextSectionItem = viewModel.sectionsWithNotes[safe: (section + 1)] {
      isSameYear = (nextSectionItem.date.MMYY == sectionItem.date.MMYY)
    }

    let itemDate = sectionItem.date
    let date = isSameYear ? itemDate.dMMMM : itemDate.dMMMMyyyy
    return DiaryTableSectionHeader(date: "\(itemDate.weekday), \(date)", averageScore: sectionItem.average)
  }

  func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

    let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (_, _, completion) in
      let noteToDeleteId = self.viewModel.sectionsWithNotes[indexPath.section].notes[indexPath.row].id
      self.viewModel.deleteNote(noteId: noteToDeleteId)
      completion(true)
      self.updateContent()
      SvetiAnalytics.log(.deleteNote)
    }

    let image = UIImage(named: "Delete")?.imageResized(to: .init(width: 22, height: 22))
    deleteAction.image = image
    deleteAction.backgroundColor = .white
    return UISwipeActionsConfiguration(actions: [deleteAction])
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let selectedNote = viewModel.sectionsWithNotes[indexPath.section].notes[indexPath.row]
    let detailNoteVC = DetailNoteVC(noteId: selectedNote.id)
    SvetiAnalytics.log(.openNote)
    self.navigationController?.pushViewController(detailNoteVC, animated: true)
  }

}
