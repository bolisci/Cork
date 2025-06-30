//
//  Package Deprecation View Minified Display.swift
//  Cork
//
//  Created by David Bureš - P on 08.06.2025.
//

import SwiftUI

struct PackageDeprecationViewMinifiedDisplay: View
{
    @AppStorage("caveatDisplayOptions") var caveatDisplayOptions: PackageCaveatDisplay = .full

    let isDeprecated: Bool

    let deprecationReason: String?

    @State private var isShowingDeprecationReason: Bool = false

    var outlinedPillText: LocalizedStringKey
    {
        if deprecationReason == nil
        {
            return "package-details.deprecation.notice.minified.no-reason-for-deprecation-provided"
        }
        else
        {
            return "package-details.deprecation.notice.minified.reason-for-deprecation-provided"
        }
    }
    
    var body: some View
    {
        if isDeprecated
        {
            if caveatDisplayOptions == .mini
            {
                OutlinedPillText(text: outlinedPillText, color: .orange)
                    .onTapGesture
                    {
                        isShowingDeprecationReason = true
                    }
                    .modify
                    { viewProxy in
                        if let deprecationReason
                        {
                            viewProxy
                                .popover(isPresented: $isShowingDeprecationReason)
                                {
                                    Text(deprecationReason)
                                }
                        }
                        else
                        {
                            viewProxy
                        }
                    }
            }
        }
    }
}
