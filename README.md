<p>
    <img src="https://github.com/user-attachments/assets/84ad8cf5-b6dd-4203-a512-f80d462a6dad" width=150px height=150px  hspace="10" alt="App Icon">
    <img src="https://github.com/user-attachments/assets/bd196fa7-6650-40b0-bca2-a07bb5cbafe9" width=150px height=150px  hspace="10" alt="Dark Mode Icon">
</p>

# Teddy: Camera via Voice
Teddy is an app to help those with touch accessibility issues still be able to capture those meaningful moments with their iPhone or iPad.

My grandfather, Larry, was a force of nature. He was kind, loving, and a mentor to many, but especially his grandchildren. He was also a fantastic photographer. Growing up, he shared his passion of photography with me and inspired my own. Whenever we traveled, he would bring along his Cannon EOS D6 with him. He taught me how to use it, how to frame a photo, and what makes an interesting photograph. When Shot on iPhone became a feasible thing for professionals, he continuously tried to take photos on his phone. Unfortunately, there wasn’t much blood in his fingers, leading to a difficulty using his phone and losing the moments he wanted to capture.

On a larger scale, there is a strong overlap between those who have touch issues and those who have difficulty learning accessibility focused features such as VoiceOver [1][2]. Teddy addresses this issue through Apple’s Foundation Models and SpeechAnalyzer APIs to take action on behalf of the user through natural language processing and tool calling.

[1] https://journals.sagepub.com/doi/10.1177/21695067231193656

[2] https://pmc.ncbi.nlm.nih.gov/articles/PMC7924826/ 

## Download

Get the TestFlight [here](https://testflight.apple.com/join/chBAxBHK)

## Technologies
Oh my gosh, there were so many fun things used! Here's a brief list of frameworks:

- UIKit
- SwiftUI
- AVKit
- AVFoundation
- CoreImage
- FoundationModels
- Speech
- TipKit

## Private APIs
Yes, Teddy uses private APIs to achieve certain aspects of the app, namely the glass backgrounds. To learn more about `_UIViewGlass`, click [here](https://www.notprivateapis.com/documentation/notprivateapis/_uiviewglass).

## AI Usage
I used AI in this project, but very minimally.

AVFoundation can be very difficult to work with and understand since many of the errors it communicates are simply bad memory access crashes. To achieve the blured bounds for the current camera where the aspect ratio of the normal preview does not cover, I had ChatGPT generate some of the structures to convert AVCaptureVideoPreviewLayer into a UIImage on frame update. Then I did all of the manual work of representing and displaying it.

Also, shout out to [Ethan Lipnik](https://x.com/EthanLipnik) for alerting me to the existance of the new SpeechAnalyzer API. To transition from a solo model of simply SFSpeechRecognizer, I used AI to do some of the heavy lifting of implementing SpeechAnalyzer and refactoring the audio input code to make everything consistent.

While AI assisted me in understanding and using these APIs, I did all of the architecture work as well as many components of integrating technological know-how to make these features come together. AI just helped to create the first draft.

## Screenshots

<p>
<img width="168.75" height="345" alt="Teddy 1" src="https://github.com/user-attachments/assets/385e2f47-e39d-4dfb-b62a-0f9e7bcc8b6b" hspace="10"/>
<img width="168.75" height="345" alt="Teddy 2" src="https://github.com/user-attachments/assets/bb90bc56-3fbd-4b95-8001-3a4bbc686b76" hspace="10"/>
<img width="168.75" height="345" alt="Teddy 3" src="https://github.com/user-attachments/assets/e19f59e0-f005-4cea-8120-67117c115a0f" hspace="10"/>
</p>
