//
//  ContentView.swift
//  Messager
//
//  Created by Aryan Mittal on 5/23/20.
//  Copyright © 2020 Aryan Mittal. All rights reserved.
//

import SwiftUI
import ColorPicker

let defaults = UserDefaults.standard
let pasteboard = UIPasteboard.general

//PRUPLE: red: 74/255, green: 26/255, blue: 99/255
//iOS PURPLE: UIColor.purple
//settings icon: ⚙
struct ContentView: View {
    @ObservedObject private var keyboard = KeyboardResponder()
    
    var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    @State var name:String = ""
    @State var message:String = ""
    @State var room:String = ""
    @State var realRoom:String = "global"
    @State var showingAlert:Bool = false
    @State var alertMessage:String = ""
    @State private var arrayMessages: [String] = []
    @State var nameColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    @State var showModal = false
    @State var showLoading = true
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @State var showMenu:Bool = false

    var timer: Timer {
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) {_ in
            self.getMessages()
        }
    }

    var body: some View {
        ZStack {
        ScrollView {
        VStack(alignment: .leading, spacing: 15) {
            
            HStack() {
                Spacer()
                Text("Messager -- AryanM").font(.system(size:25))
                Spacer()
            }
            
            Divider()
            
            if(showLoading) {
                HStack() {
                    Spacer()
                    Text("Loading Messages...").font(.system(size:20))
                    Spacer()
                }
            }
            ForEach(arrayMessages, id: \.self) { m in // show received results
                HStack(alignment: .firstTextBaseline) {
                    Text("\(m.components(separatedBy: "-")[0]),\n\(m.components(separatedBy: "-")[1]) ").bold().foregroundColor(Color.gray).frame(width:60).font(.system(size:10, design: .monospaced))
                    VStack(alignment: .leading) {
                        
                        Text("\(m.components(separatedBy: "-")[2].replacingOccurrences(of: "#DASH#", with: "-").replacingOccurrences(of: "#PIPE#", with: "|")):")
                            .bold()
                            .foregroundColor(Color(UIColor(hex: m.components(separatedBy: "-")[4], colorScheme: self.colorScheme)))
                        
                        Text(m.components(separatedBy: "-")[3].replacingOccurrences(of: "#DASH#", with: "-").replacingOccurrences(of: "#PIPE#", with: "|").replacingOccurrences(of: "$LINK~", with: " link::").replacingOccurrences(of: "~LINK$", with: "::").replacingOccurrences(of: "$IMAGE~", with: " image::").replacingOccurrences(of: "~IMAGE$", with: "::")).fixedSize(horizontal: false, vertical: true)
                        Divider()
                    }.contextMenu {
                        Button("Copy Message", action: {
                            pasteboard.string = m.components(separatedBy: "-")[3].replacingOccurrences(of: "#DASH#", with: "-").replacingOccurrences(of: "#PIPE#", with: "|").replacingOccurrences(of: "$LINK~", with: " link::").replacingOccurrences(of: "~LINK$", with: "::").replacingOccurrences(of: "$IMAGE~", with: " image::").replacingOccurrences(of: "~IMAGE$", with: "::")
                        })
                        Button("Copy Name", action: {
                            pasteboard.string = "\(m.components(separatedBy: "-")[2].replacingOccurrences(of: "#DASH#", with: "-").replacingOccurrences(of: "#PIPE#", with: "|")):"
                        })
                        Button("Copy Color \(m.components(separatedBy: "-")[4])", action: {
                            pasteboard.string = m.components(separatedBy: "-")[4]
                        })
                    }
                }
            }
            
            HStack() {
                TextField("Nickname", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onReceive(name.publisher.collect()) {
                        self.name = String($0.prefix(40))
                    }
                Button("C") {
                    
                    self.showModal.toggle()
                }.sheet(isPresented: $showModal) {
                    ColorPopup(showModal: self.$showModal, color: self.$nameColor)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 6)
                .padding(.bottom, 6)
                .background(Color(nameColor))
                //.border(Color.gray, width: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                .cornerRadius(6)
                .foregroundColor(Color.white)
                Button("Send", action: send).buttonStyle(ButtonStyler())
            }
            
            TextField("Message", text: $message).textFieldStyle(RoundedBorderTextFieldStyle())
            .frame(height: 50.0)
            .onReceive(message.publisher.collect()) {
                self.message = String($0.prefix(1000))
            }
            
            Text("")
            
            HStack() {
                TextField("Room Code", text: $room).textFieldStyle(RoundedBorderTextFieldStyle())    .disableAutocorrection(true).autocapitalization(UITextAutocapitalizationType.none)

                Button("Join", action: joinRoom).buttonStyle(ButtonStyler())
                    .alert(isPresented: $showingAlert) {
                    Alert(title: Text("Oops"), message: Text(alertMessage), dismissButton: .default(Text("Try Another Room Code")))
                }
                Button("Create", action: createRoom).buttonStyle(ButtonStyler())
            }
            
            Button(action: joinGlobalRoom) {
                HStack() {
                    Spacer()
                    Text("Join Global Room")
                    Spacer()
                }
            }.buttonStyle(ButtonStyler())
        }.frame(maxWidth: .infinity)
        .padding()
        .padding(.bottom, keyboard.currentHeight)
        .edgesIgnoringSafeArea(.bottom)
        .animation(.easeOut(duration: 0.16))
        .onAppear(perform: {
            
            if(self.name == "") {
                if let persistname = defaults.string(forKey: "persistName") {
                    if(persistname == "true") {
                        if let prename = defaults.string(forKey: "name") {
                            self.name = prename
                        }
                    }
                }
            }
            
            if let persistroom = defaults.string(forKey: "persistRoom") {
                if(persistroom == "true") {
                    if let preroom = defaults.string(forKey: "room") {
                        if(preroom != "global") {
                            self.room = preroom
                            self.realRoom = self.room
                        }
                    }
                }
            }
            if let persistcolor = defaults.string(forKey: "persistColor") {
                if(persistcolor == "true") {
                    if let prenameColor = defaults.string(forKey: "nameColor") {
                        self.nameColor = UIColor(hexString: prenameColor)
                    }
                }
            }
            
            if defaults.string(forKey: "roomHistory") == nil {
                defaults.set("global", forKey: "roomHistory")
            }
            
            self.timer.tolerance = 2
            _ = self.timer
            }).lineLimit(nil)
        }.padding(.top)
            VStack {
                HStack {
                    Spacer()
                    Button("☰") {
                        self.showMenu.toggle()
                    }.sheet(isPresented: $showMenu) {
                        MenuModal(showModal: self.$showMenu, room: self.$room, realRoom: self.$realRoom)
                    }
                    .buttonStyle(ButtonStyler(pad1: 2))
                    .font(.system(size: 30))
                }
                Spacer()
            }
        }
    }
    
    
    func joinGlobalRoom() -> Void {
        self.room = ""
        self.realRoom = "global"
        addRoomHistory(room: self.realRoom)
        defaults.set(self.realRoom, forKey: "room")
        UIApplication.shared.endEditing()
    }
    
    func joinRoom() -> Void {
        if(room == "") {
            return
        }
        var output:String = ""
        let url = URL(string: "https://vekjvwo92e.execute-api.us-east-1.amazonaws.com/prod?task=joinRoom&room=" + room)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            output = String(data: data, encoding: .utf8)!
            if(output == "Exists") {
                self.realRoom = self.room
                addRoomHistory(room: self.realRoom)
                defaults.set(self.realRoom, forKey: "room")
            } else if(output == "No Exists") {
                self.showingAlert = true
                self.alertMessage = "That chat room doesn't exist!"
            }
        }
        
        UIApplication.shared.endEditing()
        task.resume()
    }
    
    func createRoom() -> Void {
        if(room == "") {
            return
        }
        
        //date & time
        let d = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M"
        let monthNum = Int(dateFormatter.string(from: d))!
        
        dateFormatter.dateFormat = "d"
        let dayNum = String(dateFormatter.string(from: d))
        
        let date = months[monthNum-1] + " " + dayNum;
        
        dateFormatter.dateFormat = "h:mm a"
        let time = String(dateFormatter.string(from: d))
        //end date & time
        
        var output:String = ""
        var urlString = "https://vekjvwo92e.execute-api.us-east-1.amazonaws.com/prod?task=createRoom&room=" + room
        urlString += "&date=" + date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        urlString += "&time=" + time.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            output = String(data: data, encoding: .utf8)!
            if(output == "Created") {
                self.realRoom = self.room
                addRoomHistory(room: self.realRoom)
                defaults.set(self.realRoom, forKey: "room")
            } else if(output == "Exists") {
                self.showingAlert = true
                self.alertMessage = "That chat room already exists!"
            }
        }
        
        UIApplication.shared.endEditing()
        task.resume()
    }
    func send() -> Void {
        //add HTTP request for sendssages
        if(message == "") {
            return
        }
        
        defaults.set(name, forKey: "name")

        let realMessage:String = message.replacingOccurrences(of: "-", with: "#DASH#").replacingOccurrences(of: "|", with: "#PIPE#")
        
        var xname:String = name.replacingOccurrences(of: "-", with: "#DASH#").replacingOccurrences(of: "|", with: "#PIPE#")
        if(xname == "") {
            xname = "An Unnamed Scrub"
        }
        
        
        //date & time
        let d = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M"
        let monthNum = Int(dateFormatter.string(from: d))!
        
        dateFormatter.dateFormat = "d"
        let dayNum = String(dateFormatter.string(from: d))
        
        let date = months[monthNum-1] + " " + dayNum;
        
        dateFormatter.dateFormat = "h:mm a"
        let time = String(dateFormatter.string(from: d))
        
        var output:String = ""
        var urlString:String = "https://vekjvwo92e.execute-api.us-east-1.amazonaws.com/prod?task=addMessage&message=" + realMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        urlString += "&name=" + xname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        urlString += "&date=" + date.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        urlString += "&time=" + time.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        urlString += "&room=" + realRoom
        urlString += "&color=" + hexStringFromColor(color: nameColor).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let url = URL(string: urlString)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            output = String(data: data, encoding: .utf8)!
            
            self.parseMessages(input: output)
        }
        message = ""
        task.resume()
    }
    
    func updateMessages(input:String) -> Void {
        self.arrayMessages = input.components(separatedBy: "|")
        showLoading = false
    }
    func parseMessages(input:String) -> Void {
        
        var output:String = ""
        //Parse messages here
        output = input.replacingOccurrences(of: "&#58;", with: ":");

        updateMessages(input: output)
    }
    func getMessages() -> Void {
        var output:String = ""
        let url = URL(string: "https://vekjvwo92e.execute-api.us-east-1.amazonaws.com/prod?task=getMessages&room=" + realRoom)!

        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            output = String(data: data, encoding: .utf8)!
            
            self.parseMessages(input: output)
        }

        task.resume()
    }
    
}

func addRoomHistory(room:String) -> Void {
    if let roomhistory = defaults.string(forKey: "roomHistory") {
        var historyArray = roomhistory.components(separatedBy: "&HISTORY-SEPARATOR&")
        
        if let index = historyArray.firstIndex(of: room) {
            historyArray.remove(at: index)
        }
        defaults.set("\(room)&HISTORY-SEPARATOR&\(historyArray.joined(separator: "&HISTORY-SEPARATOR&"))", forKey: "roomHistory")
    } else {
        defaults.set("\(room)&HISTORY-SEPARATOR", forKey: "roomHistory")
    }
}

struct MenuModal: View {
    @Binding var showModal: Bool
    @Binding var room:String
    @Binding var realRoom:String
    @State var showSettings = false
    @State var showRoomHistory = false
    @State var showContactMe = false
    @State var showReportContent = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text("Menu").bold().font(.system(size: 40))
                VStack(spacing: 0) {
                    Button(action: {
                        self.showSettings.toggle()
                    }) {
                        HStack {
                            Text("Settings")
                            Spacer()
                        }
                    }.sheet(isPresented: $showSettings) {
                        SettingsModal(showModal: self.$showSettings)
                    }.buttonStyle(MenuButtonStyler())
                    Divider()
                    
                    Button(action: {
                        self.showRoomHistory.toggle()
                    }) {
                        HStack {
                            Text("Room History")
                            Spacer()
                        }
                    }.sheet(isPresented: $showRoomHistory) {
                        RoomHistoryModal(showModal: self.$showRoomHistory, showSettingsModal: self.$showModal, room: self.$room, realRoom: self.$realRoom)
                    }.buttonStyle(MenuButtonStyler())
                    Divider()
                    
                    Button(action: {
                        self.showContactMe.toggle()
                    }) {
                        HStack {
                            Text("Contact Me")
                            Spacer()
                        }
                    }.sheet(isPresented: $showContactMe) {
                        ContactMeModal(showModal: self.$showContactMe)
                    }.buttonStyle(MenuButtonStyler())
                    Divider()
                    
                    Button(action: {
                        self.showReportContent.toggle()
                    }) {
                        HStack {
                            Text("Report Content")
                            Spacer()
                        }
                    }.sheet(isPresented: $showReportContent) {
                        ReportContentModal(showModal: self.$showReportContent)
                    }.buttonStyle(MenuButtonStyler())
                }.border(Color.gray, width: 2)
                Text("\n")
                Text("\n")
            }.padding()
            
            VStack {
                HStack {
                    Button("← Back", action: {
                        self.showModal.toggle()
                        }).buttonStyle(ButtonStyler())
                    Spacer()
                }
                Spacer()
            }.padding()
        }
    }
}

struct MenuButtonStyler: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(16)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
    }
}

struct RoomHistoryModal: View {
    @Binding var showModal: Bool
    @Binding var showSettingsModal:Bool
    @Binding var room:String
    @Binding var realRoom:String
    @State var roomHistory = [String]()

    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Text("\n")
                    Text("Room History").font(.system(size:25))
                        .onAppear() {
                            if let roomhistory = defaults.string(forKey: "roomHistory") {
                                self.roomHistory = roomhistory.components(separatedBy: "&HISTORY-SEPARATOR&")
                            }
                        }
                    Divider()
                    ForEach(roomHistory, id: \.self) { r in
                        VStack {
                            Group {
                                HStack {
                                    Spacer()
                                    Text(r).padding(5)
                                    Spacer()
                                }
                            }
                            .contentShape(Rectangle())
                            .gesture(TapGesture(count: 1)
                            .onEnded {
                                self.room = r
                                self.realRoom = self.room
                                defaults.set(self.realRoom, forKey: "room")
                                addRoomHistory(room: r)
                                self.showSettingsModal.toggle()
                                self.showModal.toggle()
                            }).contextMenu {
                                Button("Copy Room Code", action: {
                                    pasteboard.string = r
                                })
                            }
                            Divider()
                        }
                    }
                    Spacer()
                }.padding()
            }
            VStack {
               HStack {
                   Button("← Back", action: {
                       self.showModal.toggle()
                       }).buttonStyle(ButtonStyler())
                   Spacer()
                }
               Spacer()
            }.padding()
            VStack {
                HStack {
                    Spacer()
                    Button("Clear", action: {
                        defaults.set("global", forKey: "roomHistory")
                        self.room = ""
                        self.realRoom = "global"
                        defaults.set(self.realRoom, forKey: "room")
                        self.showModal.toggle()
                        }).buttonStyle(ButtonStyler())
                 }
                Spacer()
            }.padding()
            
        }
    }
}

struct ContactMeModal: View {
    @Binding var showModal: Bool
    
    var body: some View {
        ZStack {
            VStack {
                Image("aryan")
                    .renderingMode(.original)
                    .resizable()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 1)
                        )
                    .cornerRadius(10)
                    .frame(width: 150, height: 150)
                Text("Aryan Mittal").bold().font(.system(size: 30))
                Text("\n")
                Group {
                    Text("You may contact me here:")
                    Text("aryanm.email1@gmail.com").bold()
                    .fixedSize(horizontal: false, vertical: true)
                }.contextMenu {
                    Button("Copy Email Address", action: {
                        pasteboard.string = "aryanm.email1@gmail.com"
                    })
                }
                Text("\n")
                Text("Feel free to email me with feedback and concerns!")
                    .fixedSize(horizontal: false, vertical: true)
                Text("\n")
                Text("\n")
            }
            VStack {
                HStack {
                   Button("← Back", action: {
                       self.showModal.toggle()
                       }).buttonStyle(ButtonStyler())
                   Spacer()
               }
               Spacer()
           }.padding()
        }
    }
}

struct ReportContentModal: View {
    @Binding var showModal: Bool
    let fontSize:CGFloat = 20;
    
    var body: some View {
        ZStack {
            VStack {
                Text("Report").font(.system(size:25))
                Divider()
                Text("\n")
                Text("Report content if it includes bullying, harassment, or illegal content.").font(.system(size: fontSize)).bold()
                    .fixedSize(horizontal: false, vertical: true)
                Text("\nMake sure to include the chat room and which type of content you're reporting in your report.").font(.system(size: fontSize))
                    .fixedSize(horizontal: false, vertical: true)
                Text("\n")
                Group {
                    Text("Send reports to:").font(.system(size: fontSize))
                    Text("aryanm.email1@gmail.com").bold().font(.system(size: fontSize))
                        .fixedSize(horizontal: false, vertical: true)
                }.contextMenu {
                    Button("Copy Email Address", action: {
                        pasteboard.string = "aryanm.email1@gmail.com"
                    })
                }
                Text("\n")
                Text("\n")
            }.padding()
            VStack {
               HStack {
                   Button("← Back", action: {
                       self.showModal.toggle()
                       }).buttonStyle(ButtonStyler())
                   Spacer()
                }
               Spacer()
           }.padding()
        }
    }
}

struct SettingsModal: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    @Binding var showModal: Bool
    @State var persistName:Bool = false
    @State var persistNameColor:Bool = false
    @State var persistRoom:Bool = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Group {
                        HStack {
                            Spacer()
                            Text("\n")
                            Text("Settings").font(.system(size:25))
                            Spacer()
                        }
                        Divider()
                        Text("\n")
                        Text("Tip: Toggle light/dark mode in your phone's settings (iOS 13+)").bold()  .fixedSize(horizontal: false, vertical: true)

                    }
                    
                    Group { //icon choosing group
                        Text("\n")
                        Text("Change Icon:").bold()
                        
                        VStack(spacing: 1) {
                            HStack(spacing: 20) {
                                Spacer()
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName(nil)
                                }) {
                                    Image("normal").renderingMode(.original)
                                        .resizable()
                                        .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        .cornerRadius(10)
                                        .frame(width: 90, height: 90)
                                }.fixedSize()
                                .frame(width: 90, height: 90)
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("dark")
                                }) {
                                    Image("dark").renderingMode(.original)
                                        .resizable()
                                        .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        .cornerRadius(10)
                                        .frame(width: 90, height: 90)
                                }.fixedSize()
                                .frame(width: 90, height: 90)
                                
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                Spacer()
                                Text("Light").fixedSize().frame(width:90, height:25)
                                Text("Dark").fixedSize().frame(width:90, height:25)
                                Spacer()
                            }
                        }
                        VStack(spacing: 1) {
                            HStack(spacing: 20) {
                                Spacer()
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("black")
                                }) {
                                    Image("black").renderingMode(.original)
                                        .resizable()
                                        .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        .cornerRadius(10)
                                        .frame(width: 90, height: 90)
                                }.fixedSize()
                                .frame(width: 90, height: 90)
                                
                                Button(action: {
                                    UIApplication.shared.setAlternateIconName("aryan")
                                }) {
                                    Image("aryan").renderingMode(.original)
                                        .resizable()
                                        .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.gray, lineWidth: 1)
                                            )
                                        .cornerRadius(10)
                                        .frame(width: 90, height: 90)
                                }.fixedSize()
                                .frame(width: 90, height: 90)
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                Spacer()
                                Text("Black").fixedSize().frame(width:90, height:25)
                                Text("( ͡° ͜ʖ ͡°)").fixedSize().frame(width:90, height:25)
                                Spacer()
                            }
                        }
                    }
                    
                    Group {
                        Text("\n")
                        Text("Remember these after closing Messager:").bold()
                            .fixedSize(horizontal: false, vertical: true)
                        Divider()
                    Toggle("Nickname", isOn: $persistName)
                        .onAppear {
                            if let persistname = defaults.string(forKey: "persistName") {
                                self.persistName = persistname == "true"
                            }
                        }
                    Divider()
                    Toggle("Name Color", isOn: $persistNameColor)
                        .onAppear() {
                            if let persistnameColor = defaults.string(forKey: "persistNameColor") {
                                self.persistNameColor = persistnameColor == "true"
                            }
                        }
                    Divider()
                    Toggle("Chat Room", isOn: $persistRoom)
                        .onAppear() {
                            if let persistroom = defaults.string(forKey: "persistRoom") {
                                self.persistRoom = persistroom == "true"
                            }
                        }
                    } //end toggle group
                    
                    Divider()
                    Text("\n")
                    HStack {
                        Spacer()
                        Button("Save") {
                            defaults.set(self.persistName ? "true" : "false", forKey: "persistName")
                            defaults.set(self.persistNameColor ? "true" : "false", forKey: "persistNameColor")
                            defaults.set(self.persistRoom ? "true" : "false", forKey: "persistRoom")
                            self.showModal.toggle()
                        }.buttonStyle(ButtonStyler())
                        Button("Cancel") {
                            self.showModal.toggle()
                        }.buttonStyle(ButtonStyler())
                        Spacer()
                    }
                Spacer()
                }.padding()
            }
            VStack {
                 HStack {
                    Button("← Back", action: {
                        self.showModal.toggle()
                        }).buttonStyle(ButtonStyler())
                    Spacer()
                }
                Spacer()
            }.padding()
        }
    }
}

struct ColorPopup: View {
    @Binding var showModal: Bool
    @Binding var color: UIColor
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        VStack {//colorScheme == .light ? "lightImage" : "darkImage"
            Text("Choose Name Color").font(.system(size:25)).foregroundColor(Color((color == UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0) && colorScheme == .dark) ? UIColor.white : color))
            
            ColorPicker(color: $color, strokeWidth: 40)
                .frame(width: 250, height: 250, alignment: .center)
            
            Button("Choose Default") {
                self.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                defaults.set(hexStringFromColor(color: self.color), forKey: "nameColor")
                self.showModal.toggle()
            }.buttonStyle(ButtonStyler())
            Text("\n")
            Button("Done") {
                defaults.set(hexStringFromColor(color: self.color), forKey: "nameColor")

                self.showModal.toggle()
            }.font(.system(size:20)).buttonStyle(ButtonStyler())
        }
    }
}

struct ButtonStyler: ButtonStyle {
    var pad:CGFloat = 8

    public init(pad1: CGFloat = 8) {
        self.pad = pad1
    }
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.white)
            .padding(self.pad) //74, 26, 99 // 9, 27, 79
            //.background(LinearGradient(gradient: Gradient(colors: [Color(red: 9/255, green: 27/255, blue: 79/255), Color(red: 74/255, green: 26/255, blue: 99/255)]), startPoint: .leading, endPoint: .trailing))
            .background(Color(red: 74/255, green: 26/255, blue: 99/255))
            .cornerRadius(10.0)
            .scaleEffect(configuration.isPressed ? 1.2 : 1.0)
    }
}

final class KeyboardResponder: ObservableObject {
    private var notificationCenter: NotificationCenter
    @Published private(set) var currentHeight: CGFloat = 0

    init(center: NotificationCenter = .default) {
        notificationCenter = center
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    @objc func keyBoardWillShow(notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            currentHeight = keyboardSize.height
        }
    }

    @objc func keyBoardWillHide(notification: Notification) {
        currentHeight = 0
    }
}

extension UIColor {
    
    convenience init(hex: String, alpha: CGFloat = 1.0, colorScheme:ColorScheme) {
        
        var realHex = hex
        if(hex == "#000000" && colorScheme == .dark) {
            realHex = "#FFFFFF"
        }
        var hexFormatted: String = realHex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }

        assert(hexFormatted.count == 6, "Invalid hex code used.")

        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)

        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

func hexStringFromColor(color: UIColor) -> String {
   let components = color.cgColor.components
   let r: CGFloat = components?[0] ?? 0.0
   let g: CGFloat = components?[1] ?? 0.0
   let b: CGFloat = components?[2] ?? 0.0

   let hexString = String.init(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
   return hexString
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
