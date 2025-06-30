//
//  Top Packages Section.swift
//  Cork
//
//  Created by David Bureš on 17.10.2023.
//

import SwiftUI

struct TopPackagesSection: View
{
    @EnvironmentObject var brewData: BrewDataStorage

    let packageTracker: TopPackagesTracker

    let trackerType: PackageType
    
    private var packages: [BrewPackage]
    {
        switch trackerType
        {
        case .formula:
            packageTracker.sortedTopFormulae.filter
            {
                !brewData.successfullyLoadedFormulae.map(\.name).contains($0.name)
            }
        case .cask:
            packageTracker.sortedTopCasks.filter
            {
                !brewData.successfullyLoadedCasks.map(\.name).contains($0.name)
            }
        }
    }

    @State private var isCollapsed: Bool = false

    var body: some View
    {
        Section
        {
            if !isCollapsed
            {
                ForEach(packages.prefix(15))
                { topPackage in
                    SearchResultRow(searchedForPackage: topPackage, context: .topPackages)
                }
            }
        } header: {
            CollapsibleSectionHeader(headerText: trackerType == .cask ? "add-package.top-casks" : "add-package.top-formulae", isCollapsed: $isCollapsed)
        }
    }
}
