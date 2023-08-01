//
//  SegmentViewController.swift
//  Recipe
//
//  Created by 김민호 on 2023/07/25.
//

import UIKit

class SegmentViewController: BaseViewController {
  private let segmentedControl: UISegmentedControl = {
    let segmentedControl = UnderlineSegmentedControl(items: ["리뷰", "댓글"])
    segmentedControl.translatesAutoresizingMaskIntoConstraints = false
    return segmentedControl
  }()
//  private let childView: UIView = {
//    let view = UIView()
//    view.translatesAutoresizingMaskIntoConstraints = false
//    return view
//  }()
    
    private let vc1 = RecipeReviewController()
//  private let vc1: UIViewController = {
//    let vc = RecipeReviewController()
//    vc.view.backgroundColor = .red
//    return vc
//  }()
//    private let vc2 = CommentViewController()
    private let vc2 = CommentTestViewController()
//  private let vc2: UIViewController = {
//    let vc = UIViewController()
//    vc.view.backgroundColor = .green
//    return vc
//  }()

  private lazy var pageViewController: UIPageViewController = {
    let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    vc.setViewControllers([self.dataViewControllers[0]], direction: .forward, animated: true)
    vc.delegate = self
    vc.dataSource = self
    vc.view.translatesAutoresizingMaskIntoConstraints = false
    return vc
  }()
  
  var dataViewControllers: [UIViewController] {
    [self.vc1, self.vc2]
  }
  var currentPage: Int = 0 {
    didSet {
      // from segmentedControl -> pageViewController 업데이트
      print(oldValue, self.currentPage)
      let direction: UIPageViewController.NavigationDirection = oldValue <= self.currentPage ? .forward : .reverse
      self.pageViewController.setViewControllers(
        [dataViewControllers[self.currentPage]],
        direction: direction,
        animated: true,
        completion: nil
      )
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
      let v = UILabel()
      v.text = "레시피"
      navigationItem.titleView = v
      
    self.view.addSubview(self.segmentedControl)
    self.view.addSubview(self.pageViewController.view)
    
    NSLayoutConstraint.activate([
      self.segmentedControl.leftAnchor.constraint(equalTo: self.view.leftAnchor),
      self.segmentedControl.rightAnchor.constraint(equalTo: self.view.rightAnchor),
      self.segmentedControl.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 80),
      self.segmentedControl.heightAnchor.constraint(equalToConstant: 50),
    ])
    NSLayoutConstraint.activate([
      self.pageViewController.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 4),
      self.pageViewController.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -4),
      self.pageViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4),
      self.pageViewController.view.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor, constant: 5),
    ])
    
    self.segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.mainColor], for: .normal)
    self.segmentedControl.setTitleTextAttributes(
      [
        NSAttributedString.Key.foregroundColor: UIColor.green,
        .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
      ],
      for: .selected
    )
    self.segmentedControl.addTarget(self, action: #selector(changeValue(control:)), for: .valueChanged)
    self.segmentedControl.selectedSegmentIndex = 0
    self.changeValue(control: self.segmentedControl)
      vc1.delegate = self
  }
  
  @objc private func changeValue(control: UISegmentedControl) {
    // 코드로 값을 변경하면 해당 메소드 호출 x
    self.currentPage = control.selectedSegmentIndex
  }
}

extension SegmentViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerBefore viewController: UIViewController
  ) -> UIViewController? {
    guard
      let index = self.dataViewControllers.firstIndex(of: viewController),
      index - 1 >= 0
    else { return nil }
    return self.dataViewControllers[index - 1]
  }
  func pageViewController(
    _ pageViewController: UIPageViewController,
    viewControllerAfter viewController: UIViewController
  ) -> UIViewController? {
    guard
      let index = self.dataViewControllers.firstIndex(of: viewController),
      index + 1 < self.dataViewControllers.count
    else { return nil }
    return self.dataViewControllers[index + 1]
  }
  func pageViewController(
    _ pageViewController: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController],
    transitionCompleted completed: Bool
  ) {
    guard
      let viewController = pageViewController.viewControllers?[0],
      let index = self.dataViewControllers.firstIndex(of: viewController)
    else { return }
    self.currentPage = index
    self.segmentedControl.selectedSegmentIndex = index
  }
}

extension SegmentViewController: RecipeReviewControllerDelegate {
    func didTapMorePhotoButton() {
        print(#function)
        let vc = ReviewPhotoViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
