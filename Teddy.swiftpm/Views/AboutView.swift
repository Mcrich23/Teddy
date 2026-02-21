//
//  AboutView.swift
//  Teddy
//
//  Created by Morris Richman on 12/29/25.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        Image(.teddy)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding()
                        VStack(alignment: .leading) {
                            Text("About\nTeddy")
                                .font(.largeTitle)
                                .bold()
                        }
                    }
                    
                    VStack {
                        Text("Teddy was created in loving memory of Laurence\u{00a0}N.\u{00a0}Smith")
                            .bold()
                            .multilineTextAlignment(.center)
                        
                        LarrySmithBioView()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Sources:")
                            .bold()
                        Link(destination: URL(string: "https://journals.sagepub.com/doi/10.1177/21695067231193656")!) {
                            Text("**Paper:** Older Adults Disproportionately Hindered by Touch Screen Interfaces in Driving Tasks")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Credits:")
                            .bold()
                        Text("Thank you to Apple's [AVCam](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app) sample app for providing some of the internal camera logic.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, -40)
                .padding([.bottom, .horizontal])
            }
            .glassSheet()
            .toolbar {
                Button(role: .close, action: dismiss.callAsFunction)
            }
            .toolbarTitleDisplayMode(.inline)
        }
    }
}

private struct LarrySmithBioView: View {
    @State var width: CGFloat = 0
    
    var body: some View {
        ViewThatFits(in: .horizontal) {
            if UIDevice.current.userInterfaceIdiom != .phone {
                bigImageBio
                    .frame(idealWidth: 400)
            }
            smallImageBio
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            width = newValue.width
        }

    }
    
    var image: some View {
        Image(.larrySmith)
            .resizable()
            .aspectRatio(0.6667362706, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    var bigImageBio: some View {
        TextView(text: bio, exclusionPaths: [
                .init(rect: .init(x: width*0.69, y: 0, width: 170, height: 250))
            ])
        .overlay(alignment: .topTrailing) {
            image
                .frame(width: 167, height: 250)
                .padding(.top, 12)
        }
    }
    
    var smallImageBio: some View {
        TextView(text: bio, exclusionPaths: [
                .init(rect: .init(x: width*0.67, y: 0, width: 140, height: 200))
            ])
        .overlay(alignment: .topTrailing) {
            image
                .frame(width: 134, height: 200)
                .padding(.top, 12)
        }
    }
    
    let bio: String = """
            My grandfather, Larry, was a force of nature. He was kind, loving, and a mentor to many, but especially his grandchildren. He was also a fantastic photographer. Growing up, he shared his passion of photography with me and inspired my own. Whenever we traveled, he would bring along his Cannon EOS D6 with him. He taught me how to use it, how to frame a shot, and what makes an interesting photograph. 
            
            When Shot on iPhone became feasible for professionals, he continuously tried to take photos on his phone rather than carrying his camera everywhere. Unfortunately, there wasn’t much blood in his fingers, leading to a difficulty using his phone and losing the moments he wanted to capture. While he never quite got the hang of VoiceOver, I made Teddy with the hope that he would be able to intuitively use it if he were alive today. 
            
            – Morris Richman
            """
}

#Preview {
    Image(.videoMode)
        .ignoresSafeArea()
        .scaledToFit()
        .sheet(isPresented: .constant(true)) {
            AboutView()
        }
}
