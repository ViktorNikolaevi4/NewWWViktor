import SwiftUI
import Foundation

struct ClockWidgetView: View {
    @State private var date = Date()
    var body: some View {
        VStack {
            Text(date, style: .time)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
            Text(date, style: .date)
                .font(.footnote)
                .opacity(0.7)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                date = Date()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotesWidgetView: View {
    @State private var text: String = ""
    var body: some View {
        TextEditor(text: $text)
            .padding(8)
    }
}
