//
//  ViewController.swift
//  RulerView
//
//  Created by qjshuai@126.com on 02/20/2019.
//  Copyright (c) 2019 qjshuai@126.com. All rights reserved.
//

import UIKit
import RulerView

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let ruler = RulerView(frame: CGRect(x: 100, y: 200, width: 200, height: 30))
        view.addSubview(ruler)
    }

}

