import UIKit
import ALPopup
import SPAlert

class EditTagGroupVC: VCwithTable {

  private let actionsAlertController = UIAlertController()
  private let newTagAlertController = UIAlertController(title: "Add a tag", message: nil, preferredStyle: .alert)
  private let deleteGroupAlertController = UIAlertController(title: "Attention", message: "Delete group?", preferredStyle: .alert)

  let groupId: String
  private let tagsRepository = TagsRepository()
  var editingTagId = String() // Use for update tags in actionSheet called from TagGroupCell
  private var hideAction = UIAlertAction(title: "", style: .default)

  init(groupId: String) {
    self.groupId = groupId
    super.init(with: .insetGrouped)
    let editingTableView = EditingTableView(viewModel: viewModel, style: .grouped)
    editingTableView.groupId = groupId
    tableView = editingTableView
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    onClosingCompletion()
  }

  override func logOpenScreenEvent() {
    SvetiAnalytics.log(.EditTagGroup)
  }

  override func getDataProvider() -> TableDataProvider? {
    EditTagGroupTableDataProvider(with: groupId)
  }

  override func setViewModel(with dataProvider: TableDataProvider) {
    viewModel = EditTagGroupVM(tableDataProvider: dataProvider, tagGroupId: groupId)
    viewModel.delegate = self
  }

  override func setLayout() {
    super.setLayout()
    tableView.separatorColor = .clear
    tableView.isEditing = true
    tableView.eventDebounceValue = 0

    let footerView = EditTagGroupTableFooter(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 80))
    footerView.onDeleteTapHandler = {
      self.present(self.deleteGroupAlertController, animated: true, completion: nil)
    }

    tableView.tableFooterView = footerView

    title = "Edit"
    navigationItem.largeTitleDisplayMode = .never
    setActionsAlertController()
    setNewTagButton()
    setNewTagAlert()
    setActionsForDeleteAlertController()
  }

  private func setNewTagButton() {
    let button = UIButton()
    button.snp.makeConstraints { (make) in
      make.height.width.equalTo(28)
    }
    let image = UIImage(named: "add")?.withRenderingMode(.alwaysTemplate)
    button.setImage(image, for: .normal)
    button.tintColor = .systemGreen
    button.addTarget(self, action: #selector(onNewTagTap), for: .touchUpInside)
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
  }

  private func setNewTagAlert() {
    newTagAlertController.addTextField { textField in
      textField.placeholder = "Tag name"
    }

    let addAction = UIAlertAction(title: "Add", style: .default) { _ in
      self.saveNewTag()
    }

    let dismissAction = UIAlertAction(title: "Cancel", style: .destructive) { _ in
      self.newTagAlertController.textFields?.last?.text?.removeAll()
    }

    [dismissAction, addAction].forEach { action in
      newTagAlertController.addAction(action)
    }
  }

  private func setActionsAlertController() {
    hideAction = UIAlertAction(title: "Hide", style: .default) { _ in
      self.tagsRepository.updateTagHiddenStatus(withId: self.editingTagId)
      self.onNeedToUpdateContent()
      SvetiAnalytics.log(.hideTag)
    }

    let changeGroupAction = UIAlertAction(title: "Move to group", style: .default) { _ in
      let selectGroupVC = SelectGroupVC(with: self.groupId)
      var popupVC = ALCardController()

      selectGroupVC.moovingTagId = self.editingTagId
      selectGroupVC.markAsCurrentVC = false

      selectGroupVC.onSelectionCompletion = { groupTitle in
        popupVC.dismiss(animated: true)
        self.onNeedToUpdateContent()
        SPAlert.present(title: "Done", message: "Tag moved to «\(groupTitle)»", preset: .done, haptic: .success)
        SvetiAnalytics.log(.moveTag)
      }

      popupVC = ALPopup.card(controller: selectGroupVC)
      popupVC.push(from: self)
    }

    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
      self.tagsRepository.removeTag(withId: self.editingTagId)
      self.onNeedToUpdateContent()
      SvetiAnalytics.log(.deleteTag)
    }

    let cancelAction = UIAlertAction(title: "Discard", style: .cancel)

    [hideAction, changeGroupAction, deleteAction, cancelAction].forEach { action in
      actionsAlertController.addAction(action)
    }
  }

  func showEditAlert(forTag id: String) {
    editingTagId = id
    let isTagHidden = tagsRepository.findTag(withId: id)?.isHidden ?? false
    hideAction.setValue((isTagHidden ? "Make active" : "Hide"), forKey: "title")
    present(actionsAlertController, animated: true, completion: nil)
  }

  @objc private func onNewTagTap() {
    present(newTagAlertController, animated: true)
  }

  private func saveNewTag() {
    let alertTextField = self.newTagAlertController.textFields?.last
    guard let newTagName = alertTextField?.text,
          !newTagName.isEmpty else { return }
    tagsRepository.addNewTag(withName: newTagName, groupId: groupId)
    onNeedToUpdateContent()
    alertTextField?.text?.removeAll()
    SvetiAnalytics.log(.addTag)
  }

  private func setActionsForDeleteAlertController() {
    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
      self.tagsRepository.deleteGroup(with: self.groupId)
      self.navigationController?.popViewController(animated: true)
      SPAlert.present(title: "Done", message: "Group deleted", preset: .done, haptic: .success)
      SvetiAnalytics.log(.deleteTagGroup)
    }

    let cancelAction = UIAlertAction(title: "Discard", style: .default)

    [deleteAction, cancelAction].forEach { action in
      deleteGroupAlertController.addAction(action)
    }
  }
}

extension EditTagGroupVC: ViewControllerVMDelegate {
  func onNeedToUpdateContent() {
    DispatchQueue.main.async { [self] in
      UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve) {
        guard let editTagVM = self.viewModel as? EditTagGroupVM else { return }
        editTagVM.generateCellsDataForTags()
        self.tableView.reloadData()
      }
    }
  }
}
