//
//  String+URL.swift
//  GitHubSignup-Clone
//
//  Created by AtsuyaSato on 2017/03/26.
//  Copyright © 2017年 Atsuya Sato. All rights reserved.
//

import Foundation

extension String {
    var URLEscaped: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
    }
}
