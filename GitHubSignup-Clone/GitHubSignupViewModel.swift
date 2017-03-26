//
//  GitHubSignupViewModel.swift
//  GitHubSignup-Clone
//
//  Created by AtsuyaSato on 2017/03/26.
//  Copyright © 2017年 Atsuya Sato. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class GitHubSignupViewModel {
    let validatedUsername: Driver<ValidationResult>
    let validatedPassword: Driver<ValidationResult>
    let validatedPasswordRepeated: Driver<ValidationResult>
    
    // Is signup button enabled
    let signupEnabled: Driver<Bool>
    
    // Has user signed in
    let signedIn: Driver<Bool>
    
    // Is signing process in progress
    let signingIn: Driver<Bool>
    
    init(input:(
            username: Driver<String>,
            password: Driver<String>,
            repeatedPassword: Driver<String>,
            loginTaps: Driver<Void>
        ),
         dependency:(
            API: GitHubAPI,
            validationService: GitHubValidationService,
            wireframe: Wireframe
        )) {
        let API = dependency.API
        let validationService = dependency.validationService
        let wireframe = dependency.wireframe
        
        validatedUsername = input.username
            .flatMapLatest { username in
                return validationService.validateUsername(username)
                .asDriver(onErrorJustReturn: .failed(message: "Error contacting server"))
            }
        validatedPassword = input.password
            .map { password in
                return validationService.validatePassword(password)
            }
        
        validatedPasswordRepeated = Driver.combineLatest(input.password, input.repeatedPassword, resultSelector: validationService.validateRepeatedPassword)
        
        let signingIn = ActivityIndicator()
        self.signingIn = signingIn.asDriver()
        
        let usernameAndPassword = Driver.combineLatest(input.username, input.password){ ($0, $1) }
    
        signedIn = input.loginTaps.withLatestFrom(usernameAndPassword)
            .flatMapLatest { (username, password) in
                return API.signup(username, password: password)
                    .trackActivity(signingIn)
                    .asDriver(onErrorJustReturn: false)
            }
            .flatMapLatest { loggedIn -> Driver<Bool> in
                let message = loggedIn ? "Mock: Signed in to GitHub." : "Mock: Sign in to GitHub failed"
                return  wireframe.promptFor(message, cancelAction: "OK", actions: [])
                    .map { _ in
                        loggedIn
                    }
                    .asDriver(onErrorJustReturn: false)
            }
        
        signupEnabled = Driver.combineLatest(validatedUsername, validatedPassword, validatedPasswordRepeated, signingIn){
            username, password, repeatPassword, signingIn in
            username.isValid && password.isValid && repeatPassword.isValid && !signingIn
        }
        .distinctUntilChanged()
    }
}
