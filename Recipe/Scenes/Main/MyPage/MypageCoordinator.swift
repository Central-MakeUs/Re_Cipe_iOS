//
//  GoCoordinator.swift
//  Recipe
//
//  Created by KindSoft on 2023/07/03.
//

import UIKit
import PDFKit

final class MypageCoordinator: MypageCoordinatorProtocol, CoordinatorFinishDelegate {
    weak var finishDelegate: CoordinatorFinishDelegate?
    
    var navigationController: UINavigationController
    
    var childCoordinators: [Coordinator] = []
    
    var type: CoordinatorType { .myPage }
    
    required init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        startReadyFlow()
    }
    
    deinit {
        print("🍎\(String(describing: Self.self)) deinit.")
    }
    
    func showRegisterFlow() {
        let registerCoordinator = RegisterCoordinator(navigationController)
        registerCoordinator.finishDelegate = self
        registerCoordinator.start()
        childCoordinators.append(registerCoordinator)
    }
    
    func startReadyFlow()  {
        let goVC = MypageViewController()
        goVC.didSendEventClosure = { [weak self] event in
            switch event {
            case .go:
                self?.finishDelegate?.coordinatorDidFinish(childCoordinator: self!)
                return
            case .favoriteReceipeButtonTapped:
                guard let favoriteRecipeInfo = goVC.favoriteRecipe else { return }
                let vc = FavoriteRecipeViewController(data1: favoriteRecipeInfo.data)
                self?.navigationController.pushViewController(vc, animated: true)
                return
            case .writeRecipeButtonTapped:
                guard let writeRecipeInfo = goVC.writeRecipe else { return }
                print("Coordinator: \(writeRecipeInfo)")
                let vc = WriteRecipeViewController(data1: writeRecipeInfo.data)
                self?.navigationController.pushViewController(vc, animated: true)
                return
            case .myReviewButtonTapped:
                let vc = MyReviewViewController()
                self?.navigationController.pushViewController(vc, animated: true)
                return
            case .recentShortFormCellTapped:
                ///Todo:
                return
            case .recentRecipeCellTapped:
                ///Todo:
                return
            case .settingButtonTapped:
                let vc = SettingViewController()
                vc.didSendEventClosure = { [weak self] event in
                    switch event {
                    case .withdrawal:
                        self?.finishDelegate?.coordinatorDidFinish(childCoordinator: self!)
                        return
                    }
                }
                self?.navigationController.pushViewController(vc, animated: true)
                return
            }
        }
        navigationController.pushViewController(goVC, animated: true)
    }
}

extension MypageCoordinator {
    func deleteChild(_ child: Coordinator) {
        guard let index = childCoordinators.firstIndex(where: { $0 === child }) else {
            return
        }
        childCoordinators.remove(at: index)
    }
    
    func coordinatorDidFinish(childCoordinator: Coordinator) {
        childCoordinators = childCoordinators.filter({ $0.type != childCoordinator.type })
        
        switch childCoordinator.type {
        case .register:
            navigationController.viewControllers.removeAll()
            startReadyFlow()
        default:
            break
        }
    }
}
