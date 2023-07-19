//
//  CookStepCell.swift
//  Recipe
//
//  Created by 김민호 on 2023/07/17.
/// Todo: 참고해서 짜보기 https://velog.io/@j_aion/UIKit-Modern-Collection-View-Edit-with-Diffable-DataSource-nn0jddl0

import UIKit
import RxCocoa
import RxSwift
import SnapKit

final class CookStepCell: UICollectionViewCell {
    
    ///UI Properties
    private let stepBackground: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 5
        return v
    }()
    
    let stepTextView: UITextView = {
        let v = UITextView()
//        v.font = .systemFont(ofSize: 15)
//        v.textColor = .mainColor
        v.text = "asdas"
        v.sizeToFit()
        v.isScrollEnabled = false
        return v
    }()
    
    let stepTextfield: PaddingUITextField = {
        let v = PaddingUITextField()
        v.text = "안녕하세요"
        return v
    }()
    
    private let stepMoveButton: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(named: "hamburger"), for: .normal)
        return v
    }()
    
    let addPhotoButton: UIButton = {
        let v = UIButton()
        v.setImage(UIImage(systemName: "photo.fill"), for: .normal)
        v.tintColor = .gray
        return v
    }()
    
    let selectImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        v.image = UIImage(named: "popcat")
        v.layer.cornerRadius = 5
        v.clipsToBounds = true
        return v
    }()
    
    private let deletePhotoButton: DefaultCircleButton = {
        let v = DefaultCircleButton()
        let img = v.buttonImageSize(systemImageName: "minus", size: 20)
        v.setImage(img, for: .normal)
        v.backgroundColor = .mainColor
        v.tintColor = .white
        return v
    }()
    
    ///Properties
    private let disposeBag = DisposeBag()
    var defaultCheck = BehaviorRelay(value: false)
    let imageSelectSubject = PublishRelay<UIImage>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addViews()
//        configureLayout()
//        defaultSetting()
        bind()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        defaultCheck.subscribe(onNext: { isNewData in
            if isNewData {
                self.stepBackground.addDashedBorder()
                self.defaultSetting()
            } else {
                self.configureLayout()
            }
        }).disposed(by: disposeBag)
    }
}

//MARK: - Method(Normal)
extension CookStepCell {
    
    private func addViews() {
        addSubViews(stepBackground, stepMoveButton, selectImageView, addPhotoButton, deletePhotoButton)
    }
    
    private func configureLayout() {
        stepBackground.layer.borderWidth = 1
        stepBackground.layer.borderColor = UIColor.mainColor?.cgColor
        addSubview(stepTextView)
        stepBackground.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        stepTextView.snp.makeConstraints {
            $0.centerY.equalTo(stepBackground)
            $0.left.equalTo(stepBackground).inset(10)
            $0.width.equalToSuperview().dividedBy(1.5)
        }
        
        addPhotoButton.snp.makeConstraints {
            $0.centerY.equalTo(stepBackground)
            $0.left.equalTo(stepTextView.snp.right).offset(20)
        }
        
        selectImageView.snp.makeConstraints {
            $0.top.bottom.equalTo(stepBackground).inset(5)
            $0.left.equalTo(stepTextView.snp.right)
            $0.right.equalTo(stepMoveButton.snp.left).offset(-20)
            $0.width.equalTo(40)
            $0.height.equalTo(40)
        }
        
        stepMoveButton.snp.makeConstraints {
            $0.centerY.equalTo(stepBackground)
            $0.right.equalTo(stepBackground).inset(10)
        }
        didPhotoExist()
    }
    
    func defaultSetting() {
        addSubview(stepTextfield)
        stepMoveButton.setImage(UIImage(named: "hamburger_gray"), for: .normal)
        stepBackground.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
//        stepTextView.snp.makeConstraints {
////            $0.edges.equalToSuperview()
//            $0.top.equalToSuperview().inset(10)
//            $0.left.equalTo(stepBackground).inset(15)
//            $0.width.equalToSuperview().dividedBy(1.5)
////            $0.height.equalTo(50)
//            $0.bottom.equalToSuperview().inset(10)
//        }
        
        stepTextfield.snp.makeConstraints {
            $0.top.left.bottom.equalToSuperview()
            $0.width.equalToSuperview().dividedBy(1.5)
        }
        
        addPhotoButton.snp.makeConstraints {
            $0.centerY.equalTo(stepBackground)
            $0.right.equalTo(stepMoveButton.snp.left).offset(-20)
        }
        
        stepMoveButton.snp.makeConstraints {
            $0.centerY.equalTo(stepBackground)
            $0.right.equalTo(stepBackground).inset(10)
        }
    }
    
    func didPhotoExist() {
        addPhotoButton.isHidden = true
        deletePhotoButton.snp.makeConstraints {
            $0.top.equalTo(selectImageView).offset(-3)
            $0.right.equalTo(selectImageView).offset(10)
        }
    }
    
//    func addSetting(text: String) {
//        stepLabel.text = text
//    }
}

extension CookStepCell {
    func bind() {
        imageSelectSubject.subscribe(onNext: { img in
            self.selectImageView.image = img
        }).disposed(by: disposeBag)
        
//        stepTextfield.rx.controlEvent(.editingDidEndOnExit)
//            .subscribe(onNext: { _ in
//
//            }).disposed(by: disposeBag)
    }
}

//MARK: - Cell Preview
import SwiftUI
struct ForCookStepCell: UIViewRepresentable {
    typealias UIViewType = UIView

    func makeUIView(context: Context) -> UIView {
        CookStepCell()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}

@available(iOS 13.0, *)
struct CookStepCell_Preview: PreviewProvider {
    static var previews: some View {
        ForCookStepCell()
            .previewLayout(.fixed(width: 339, height: 60))
    }
}
