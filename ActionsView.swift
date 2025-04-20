import SwiftUI

struct ActionsView: View {
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "bolt.circle")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            Text("Actions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 8)
            Spacer()
        }
        .accessibility(identifier: "ActionsView")
    }
}

struct ActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsView()
    }
}