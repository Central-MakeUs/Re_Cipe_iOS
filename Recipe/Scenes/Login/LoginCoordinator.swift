//
//  LoginCoordinator.swift
//  Recipe
//
//  Created by KindSoft on 2023/07/03.
//

import UIKit

final class LoginCoordinator: LoginCoordinatorProtocol {
    
    weak var finishDelegate: CoordinatorFinishDelegate?
    
    var navigationController: UINavigationController
    
    var childCoordinators: [Coordinator] = []
    
    var type: CoordinatorType { .login }
        
    required init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
        
    func start() {
        showLoginViewController()
    }
    
    deinit {
        print("🍎\(String(describing: Self.self)) deinit.")
    }
    
    func showRegisterFlow() {
        let registerCoordinator = RegisterCoordinator(navigationController)
        registerCoordinator.finishDelegate = self
        registerCoordinator.delegate = self
        registerCoordinator.start()
        childCoordinators.append(registerCoordinator)
    }
    
    func showLoginViewController() {
        let loginVC: LoginViewController = .init()
        loginVC.didSendEventClosure = { [weak self] event in
            switch event {
            case .register:
                self?.showRegisterFlow()
            case .isMember:
                self?.endFlow()
            }
        }
        
        navigationController.pushViewController(loginVC, animated: true)
    }
    
    func endFlow() {
        finishDelegate?.coordinatorDidFinish(childCoordinator: self)
    }
    
    func deleteChild(_ child: Coordinator) {
        guard let index = childCoordinators.firstIndex(where: { $0 === child }) else {
            return
        }
        childCoordinators.remove(at: index)
    }
}

extension LoginCoordinator: CoordinatorFinishDelegate {
    func coordinatorDidFinish(childCoordinator: Coordinator) {
        childCoordinators = childCoordinators.filter({ $0.type != childCoordinator.type })
        switch childCoordinator.type {
        case .register:
            finish()
//            navigationController.viewControllers.removeAll()
//            finishDelegate?.coordinatorDidFinish(childCoordinator: self)
            
//            print(childCoordinator.navigationController)
//            print(self.navigationController)
////            finishDelegate?.coordinatorDidFinish(childCoordinator: self)
////            finishDelegate?.coordinatorDidFinish(childCoordinator: childCoordinator)
//            print("삭제전:", childCoordinators)
//            deleteChild(childCoordinator)
//            print("삭제후:", childCoordinators)
//            finishDelegate?.coordinatorDidFinish(childCoordinator: self)
        default:
            break
        }
    }
}

extension LoginCoordinator: RegisterCoorProtocol {
    func failRegister(_ coordinator: RegisterCoordinator) {
        deleteChild(coordinator)
    }
}
