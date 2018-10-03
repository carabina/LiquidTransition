//
//  TestBrokenAnimationController.swift
//  CardsNavigation
//
//  Created by Alexander Graschenkov on 01.10.2018.
//  Copyright © 2018 Alex Development. All rights reserved.
//

import UIKit

class TestBrokenAnimationController: UIViewController {

    @IBOutlet var imgView: UIImageView!
    var dismissFromPoint: CGPoint = CGPoint(x: 100, y: 100)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func onPan(pan: UIPanGestureRecognizer) {
        if pan.state == .began {
            dismissFromPoint = pan.location(in: pan.view)
            dismiss(animated: true, completion: nil)
        } else if pan.state == .changed {
            let offset = pan.translation(in: pan.view)
            let progress = min(1, max(offset.y / 300.0, 0))
            LiquidTransition.shared.update(progress: progress)
        } else if pan.state == .ended {
            LiquidTransition.shared.finish()
        }
    }

}
