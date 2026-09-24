import SwiftUI

struct EmptyStateView: View {

    var body: some View {

        VStack(spacing: 12) {

            ZStack {

                Circle()
                    .fill(
                        Color.accentColor.opacity(0.10)
                    )
                    .frame(
                        width: 64,
                        height: 64
                    )

                Image(
                    systemName: "doc.on.clipboard"
                )
                .font(.system(
                    size: 26,
                    weight: .medium
                ))
                .foregroundColor(
                    .accentColor
                )
            }

            Text("Clipboard is empty")
                .font(.system(
                    size: 15,
                    weight: .semibold
                ))

            Text(
                "Copy something and it will appear here."
            )
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(30)
    }
}
