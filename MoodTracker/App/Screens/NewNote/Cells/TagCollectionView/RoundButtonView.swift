import UIKit

enum RoundButtonState {
  case first
  case second
}

class RoundButtonView: UIView {

  private var firstStateImage: UIImage?
  private var secondStateImage: UIImage?

  private var state: RoundButtonState = .first

  let imageView = UIImageView()
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = frame.size.width / 2
  }

  init(firstStateImage: String, secondStateImage: String? = nil) {
    super.init(frame: .zero)
    setStateImages(firstName: firstStateImage, secondName: secondStateImage)
    setLayout()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setLayout() {
    backgroundColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1).withAlphaComponent(0.5)
    snp.makeConstraints { (make) in
      make.height.width.equalTo(33)
    }
    setImageView()
  }

  private func setImageView() {
    imageView.image = firstStateImage
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .black.withAlphaComponent(0.4)
    addSubview(imageView)
    imageView.snp.makeConstraints { (make) in
      make.height.width.equalTo(15)
      make.centerX.centerY.equalToSuperview()
    }
  }

  private func setStateImages(firstName: String, secondName: String?) {
    self.firstStateImage = UIImage(named: firstName)?.withRenderingMode(.alwaysTemplate)
    guard let secondName = secondName else { return }
    self.secondStateImage = UIImage(named: secondName)?.withRenderingMode(.alwaysTemplate)
  }

  func toggle() {
    DispatchQueue.main.async { [self] in
      let isFirstState = (state == .first)
      imageView.image = isFirstState ? secondStateImage : firstStateImage
      state = isFirstState ? .second : .first
    }
  }

  func setStateImage(isExpanded: Bool) {
    imageView.image = isExpanded ? secondStateImage : firstStateImage
  }
}
