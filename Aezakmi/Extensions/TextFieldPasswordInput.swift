//
//  TextFieldPasswordInput.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import Foundation
import SwiftUI

struct TextFieldPasswordInput: View {
    @State var description: String
    @State var title: String
    
    @Binding var text: String
    @Binding var isAction: Bool
    
    @State var icone: String
    @State var icone2: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(description)
                .font(.system(size: 14, weight: .regular))
            HStack {
                if isAction {
                    TextField("\(title)", text: $text)
                        .font(.system(size: 16, weight: .regular))
                        .keyboardType(.decimalPad)
                } else {
                    SecureField("\(title)", text: $text)
                        .font(.system(size: 16, weight: .regular))
                        .keyboardType(.decimalPad)
                }
                Button(action: {
                    withAnimation(.easeInOut){
                        isAction.toggle()
                    }
                }){
                    if isAction {
                        Image(systemName: icone)
                    } else {
                        Image(systemName: icone2)
                    }
                }
                .foregroundStyle(Color.theme.Colorblack)
            }
            .frame(height: 56)
            .padding(.horizontal)
            .background(Color.theme.Colorgray)
            .clipShape(.rect(cornerRadius: 10))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.gray)
            )
           
        }.padding(.init(top: 16, leading: 16, bottom: 5, trailing: 16))

    }
}

#Preview {
    TextFieldSecureInput(description: "Email address", title: "example@gmail.com", text: .constant("Email"), isAction: .constant(false), icone: "checkmark.circle.fill")
}


struct TextFieldSecureInput: View {
    
    @State var description: String
    @State var title: String
    
    @Binding var text: String
    @Binding var isAction: Bool
    @State var icone: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(description)
                .font(.system(size: 14, weight: .regular))
            HStack {
                TextField("\(title)", text: $text)
                    .font(.system(size: 16, weight: .regular))
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut){
                            isAction.toggle()
                        }
                    }){
                        Image(systemName: icone)
                    }
                    .foregroundStyle(Color.theme.Colorblack)
                }
            }
            .frame(height: 56)
            .padding(.horizontal)
            .background(Color.theme.Colorgray)
            .clipShape(.rect(cornerRadius: 10))
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.gray)
            )
        }.padding(.init(top: 16, leading: 16, bottom: 5, trailing: 16))

    }
}

#Preview {
    TextFieldSecureInput(description: "Email address", title: "example@gmail.com", text: .constant("Email"), isAction: .constant(false), icone: "checkmark.circle.fill")
}
