import SwiftUI

// The surface treatments the user can pick from the top-right menu.
enum GlassStyle: String, CaseIterable, Identifiable {
    case glass     // glass card + glass clock fields (everything Liquid Glass)
    case frosted   // .thinMaterial card + glass clock fields

    var id: String { rawValue }

    var label: String {
        switch self {
        case .glass:   "Glas-Hintergrund"
        case .frosted: "Mattierter Hintergrund"
        }
    }

    var symbol: String {
        switch self {
        case .glass:   "square.on.square.intersection.dashed"
        case .frosted: "square.fill"
        }
    }
}

struct ContentView: View {
    // Persisted across launches.
    @AppStorage("glassStyle") private var style: GlassStyle = .glass
    @State private var showStylePicker = false

    // Fixed design canvas — everything is laid out here and scaled uniformly to
    // the window, so the whole UI grows together as one proportioned unit.
    private static let designSize = CGSize(width: 420, height: 580)

    private static let analogSize = CGSize(width: 288, height: 288)
    private static let digitalSize = CGSize(width: 288, height: 104)
    private static let digitalCorner: CGFloat = 22
    private static let clockSpacing: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            // The clock cluster scales uniformly (round clock stays round); the
            // card always fills the whole window.
            let scale = min(geo.size.width / Self.designSize.width,
                            geo.size.height / Self.designSize.height)

            ZStack {
                // Card filling the ENTIRE window, with the two clock areas erased
                // clean through to the transparent window. The `.destinationOut`
                // eraser shares the same scaled+centered cluster as the visible
                // clocks, so the holes line up exactly. compositingGroup() scopes
                // the blend to this ZStack so it only eats the card, not what's
                // behind the window.
                ZStack {
                    cardFill
                    clockCluster(role: .eraser)
                        .frame(width: Self.designSize.width, height: Self.designSize.height)
                        .scaleEffect(scale)
                }
                .compositingGroup()

                // The visible content: the glass sits over the holes and refracts
                // the desktop directly (Control Center look).
                clockCluster(role: .content)
                    .frame(width: Self.designSize.width, height: Self.designSize.height)
                    .scaleEffect(scale)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .frame(minWidth: 360, maxWidth: .infinity,
               minHeight: 497, maxHeight: .infinity)
        .background(WindowAccessor())
        .preferredColorScheme(.dark)
    }

    // MARK: - Card background

    @ViewBuilder
    private var cardFill: some View {
        let shape = RoundedRectangle(cornerRadius: 19, style: .continuous)
        switch style {
        case .glass:
            Color.clear.glassEffect(.regular, in: shape)
        case .frosted:
            Rectangle().fill(.thinMaterial).clipShape(shape)
        }
    }

    // MARK: - Style menu (top-right)

    // A plain Button (not a Menu) so the trigger honors its custom size — a Menu
    // label clamps the icon to the standard control size no matter what. The
    // button opens a small popover with the style choices.
    private var styleMenu: some View {
        Button {
            showStylePicker.toggle()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .resizable()
                .scaledToFit()
                .fontWeight(.semibold)
                .frame(width: 17, height: 17)
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 38, height: 38)
                .glassEffect(.regular, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showStylePicker, arrowEdge: .bottom) {
            // Native macOS convention: a leading checkmark marks the active item;
            // the other rows keep the column blank so the labels stay aligned.
            VStack(alignment: .leading, spacing: 0) {
                ForEach(GlassStyle.allCases) { s in
                    Button {
                        style = s
                        showStylePicker = false
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .opacity(s == style ? 1 : 0)
                                .frame(width: 14)
                            Text(s.label)
                            Spacer(minLength: 16)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .frame(width: 230)
        }
    }

    // MARK: - Clock cluster

    enum SurfaceRole { case eraser, content }

    @ViewBuilder
    private func clockCluster(role: SurfaceRole) -> some View {
        VStack(spacing: 0) {
            // Header row: the GLASSTIME title centered, with the style button on
            // the trailing edge at the SAME height. The fixed height keeps the row
            // identical in eraser mode (where the button isn't drawn), so the
            // punched holes stay aligned with the glass.
            ZStack {
                Text("GLASSTIME")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .kerning(5)
                    .foregroundStyle(.white.opacity(0.55))
                    .shadow(color: .black.opacity(0.5), radius: 4)
                    // The title must not carve into the card — keep its layout,
                    // draw nothing, in eraser mode.
                    .opacity(role == .eraser ? 0 : 1)

                if role == .content {
                    HStack {
                        Spacer()
                        styleMenu
                            .offset(x: 26)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Balance the gap below the digital clock against the gap between
            // the GLASSTIME title and the analog clock. The two spacers split
            // the 66pt of free space evenly (33 each) unless a minLength forces
            // one larger. The top gap carries ~55pt of fixed extra the bottom
            // doesn't (header bottom padding + empty space below the title +
            // the analog clock's internal top inset), measured from a running
            // build. Forcing the bottom spacer to ~60pt (leaving ~6pt on top)
            // makes both visible gaps land at ~60pt.
            Spacer(minLength: 0)

            clockStack(role: role)

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 44)
    }

    private func clockStack(role: SurfaceRole) -> some View {
        // The GlassEffectContainer lets the two glass surfaces share one pass; the
        // eraser uses the same container so the holes match the glass exactly.
        GlassEffectContainer(spacing: Self.clockSpacing) {
            VStack(spacing: Self.clockSpacing) {
                clockSurface(shape: Circle(), size: Self.analogSize, role: role) {
                    AnalogClockView()
                }
                clockSurface(
                    shape: RoundedRectangle(cornerRadius: Self.digitalCorner, style: .continuous),
                    size: Self.digitalSize,
                    role: role
                ) {
                    DigitalClockView()
                }
            }
        }
    }

    // eraser  -> opaque shape that punches a hole (.destinationOut).
    // content -> the clock view backed by real Liquid Glass clipped to the shape.
    //
    // The frame is applied BEFORE the glass so the surface covers the full shape
    // (matching the hole); applying it after let the glass shrink to the digital
    // text and left a transparent ring around the lower clock.
    @ViewBuilder
    private func clockSurface<S: InsettableShape, Content: View>(
        shape: S,
        size: CGSize,
        role: SurfaceRole,
        @ViewBuilder content: () -> Content
    ) -> some View {
        switch role {
        case .eraser:
            shape.fill(.black)
                .frame(width: size.width, height: size.height)
                .blendMode(.destinationOut)

        case .content:
            content()
                .frame(width: size.width, height: size.height)
                .glassEffect(.regular, in: shape)
        }
    }
}
