import UIKit

class ScoreTimeView: UIView {

  let scoreLabel = UILabel()
  let timeLabel = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with note: Note) {
    timeLabel.text = getTime(from: note)
    scoreLabel.text = MathHelper().getAverageMood(from: note)
    //scoreLabel.textColor = ColorHelper().getColor(value: MathHelper().getAverageMood(from: note), alpha: 1.0)
  }

  private func getTime(from note: Note) -> String {
    return "в \(note.splitDate?.HHmm ?? "")"
  }

  private func setLayout() {
    setLabelsStyle()
    setLabelsLayout()
  }

  private func setLabelsStyle() {
    scoreLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
    scoreLabel.textColor = .blue
    timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
  }

  private func setLabelsLayout() {
    let stackView = UIStackView(arrangedSubviews: [scoreLabel, timeLabel])
    stackView.axis = .horizontal
    stackView.alignment = .firstBaseline
    stackView.spacing = 6

    addSubview(stackView)
    stackView.snp.makeConstraints { (make) in
      make.top.left.right.bottom.equalToSuperview()
    }
  }

}
