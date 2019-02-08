//
//  StartViewController.swift
//
//
//  Created by Alex Kovalov on 5/29/18.
//  Copyright © 2018 . All rights reserved.
//

import UIKit

class StartViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var startButton: UIButton!
    
    
    // MARK: - Properties
    
    weak var pageController: PageViewController?
    
    var complitionHandler: (() -> Void)?
    
    
    
    // MARK: - Lifecycle
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        pageController = segue.destination as? PageViewController
        pageController?.pagerDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPageControl()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.addGradient(Constant.blueGradient)
    }
    
    
    // MARK: - Actions
    
    @IBAction func startButtonPressed(_ sender: UIButton) {
        
        SettingsManager.shared.onboardingShowed = true
        (UIApplication.shared.delegate as? AppDelegate)?.window?.rootViewController = TabBarController.initFrom(.tabBar)
    }
    
    private func setupPageControl() {
        
        pageControl.numberOfPages = pageController?.items.count ?? 0
    }
}


// MARK: - PageViewControllerDelegate

extension StartViewController: PageViewControllerDelegate {
    
    func pageViewController(_ controller: PageViewController, didChangeViewControllerWith index: Int) {
        
        pageControl.currentPage = index
        UIView.animate(withDuration: 0.3) {
            self.startButton.alpha = index != (self.pageControl.numberOfPages - 1) ? 0 : 1
        }
    }
}
