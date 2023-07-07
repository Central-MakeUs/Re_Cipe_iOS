//
//  GoViewController.swift
//  Recipe
//
//  Created by KindSoft on 2023/07/03.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class MypageViewController: BaseViewController {
    
    var didSendEventClosure: ((MypageViewController.Event) -> Void)?
    var disposeBag = DisposeBag()
    
    private let button: UIButton = {
        let v = UIButton()
        v.setTitle("로그아웃", for: .normal)
        v.setTitleColor(.black, for: .normal)
        return v
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(button)
        
        button.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        button.rx.tap
            .subscribe(onNext: { _ in
                self.didSendEventClosure?(.go)
            }).disposed(by: disposeBag)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        disposeBag = DisposeBag()
    }
    
    enum Event {
        case go
    }
}