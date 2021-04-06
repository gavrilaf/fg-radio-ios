//
//  AboutView.swift
//  FGRadio
//
//  Created by Eugen Fedchenko on 19.08.2020.
//  Copyright © 2020 Eugen Fedchenko. All rights reserved.
//

import SwiftUI

let aboutText = """
Ещё одно направление от студии First Gear Show.
Мы создали автомобильное радио для тех кто любит и понимает в авто. В эфире вы услышите не только самую качественную музыку, но и программы о сервисе, истории автомобилей, автоспорте. Голоса самых ярких звёзд автоспорта, как отечественных, так и зарубежных.

Команда FirstGearShow
"""

struct AboutView: View {
    @Binding var isVisible: Bool
    
    var content: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Spacer()
                Button(action: {
                    self.isVisible = false
                }) {
                    Image(systemName: "xmark").foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            HStack {
                Spacer()
                Text("О нас")
                    .foregroundColor(Color.primaryText)
                    .font(.title)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Text("Продюсер")
                        .foregroundColor(Color.secondaryText)
                        .bold()
                    Text("Александр Федченко")
                        .foregroundColor(Color.primaryText)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Разработка")
                        .foregroundColor(Color.secondaryText)
                        .bold()
                    Text("Евгений Федченко")
                        .foregroundColor(Color.primaryText)
                        .bold()
                }
                
                VStack(alignment: .leading) {
                    Text("Дизайнер")
                        .foregroundColor(Color.secondaryText)
                        .bold()
                    Text("Евгений Белик")
                        .foregroundColor(Color.primaryText)
                        .bold()
                }
            }
            
            VStack(alignment: .leading) {
                Text("First Gear radio")
                    .foregroundColor(Color.primaryText)
                    .bold()
                Text(aboutText)
                    .foregroundColor(Color.primaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil)
            }.padding(.vertical)
            
            Text("Контактный номер для рекламодателей и партнеров:")
                .foregroundColor(Color.primaryText)
                .multilineTextAlignment(.leading)
            
            Button("067 128-55-88") {
                self.call()
            }
            
            Spacer()
        }.padding()
    }
    
    var body: some View {
        ZStack {
            Color.mainBackground.opacity(0.85).edgesIgnoringSafeArea(.vertical)
            self.content
        }
    }
    
    func call() {
        UIApplication.shared.open(phone)
    }
    
    let phone = URL(string: "tel://0671285588")!
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(isVisible: .constant(true))
    }
}
