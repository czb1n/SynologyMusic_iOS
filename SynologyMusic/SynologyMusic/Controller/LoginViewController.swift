//
//  LoginViewController.swift
//  SynologyMusic
//
//  Created by czb1n on 2022/9/29.
//

import RxSwift
import UIKit
import Toast_Swift

extension LoginViewController: FromMainStoryboard {}

class LoginViewController: UIViewController {
    var disposeBag = DisposeBag()

    @IBOutlet var hostTextFiled: UITextField!
    @IBOutlet var accountTextFiled: UITextField!
    @IBOutlet var passwordTextFiled: UITextField!
    @IBOutlet var loginButton: UIButton!

    override func viewDidLoad() {
        hostTextFiled.text = SMSynologyManager.shared.host
        accountTextFiled.text = SMSynologyManager.shared.account
        passwordTextFiled.text = SMSynologyManager.shared.password

        loginButton.layer.masksToBounds = true
        loginButton.layer.cornerRadius = 25.0
        loginButton.rx.tap.subscribe { [unowned self] _ in
            self.login()
        }.disposed(by: disposeBag)
    }

    func login() {
        SMSynologyManager.shared.host = hostTextFiled.text ?? ""
        SMSynologyManager.shared.account = accountTextFiled.text ?? ""
        SMSynologyManager.shared.password = passwordTextFiled.text ?? ""
        SMSynologyManager.shared.login { [unowned self] success in
            if success {
                self.dismiss(animated: true)
            } else {
                Debug.log("login failure")
                self.view.makeToast("登录失败", position: .center)
            }
        }
    }
}
