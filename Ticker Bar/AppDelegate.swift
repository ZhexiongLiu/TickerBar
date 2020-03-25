//
//  AppDelegate.swift
//  To-do Bar
//
//  Created by Zhexiong Liu on 3/25/20.
//  Copyright © 2020 Zhexiong Liu. All rights reserved.
//


import Cocoa
import SwiftUI
import NaturalLanguage
import Foundation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var statusBarItem: NSStatusItem!
    var titleString = "Ticker"
    var numberCount = 0
    var timeCount = 0
    let interval = 20
    var titleList: [String: String] = [:]


    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)


    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)

    }

    @objc func update_buttom(title: String) {
        if let button = self.statusItem.button {
            DispatchQueue.main.async {
//                button.image = NSImage(named: "BarIcon")
//                button.title = String("Ticker")

                if title != "" {
                    button.title = String(title)
                    button.imagePosition = NSControl.ImagePosition.imageLeft
                } else {
//                    button.imagePosition = NSControl.ImagePosition.imageOnly
                    button.title = String("Ticker")
                }
            }
        }
    }


    @objc func convertStringToDictionary(text: String) -> [String: AnyObject]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)]) as? [String: AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }


    @objc func updateData() {


        let candidates = ["CNY=X", "GC=F", "^SP500TR", "BTC-USD", ] //
        let statusBarMenu = NSMenu(title: "TodoMenuBar")
//        statusBarMenu.minimumWidth = CGFloat(defaultWidth)
        self.statusItem.menu = statusBarMenu


        statusBarMenu.addItem(NSMenuItem.separator())


        let date = NSDate()
        let fmt = DateFormatter()
        fmt.dateFormat = "ss"
        let second = Int(fmt.string(from: date as Date))

        for symbol in candidates {

            getData(symbol: symbol)

            if titleList[symbol] != nil {
                statusBarMenu.addItem(
                        withTitle: titleList[symbol]!,
                        action: #selector(AppDelegate.DoNothingAPP),
                        keyEquivalent: "")
            }
        }

        statusBarMenu.addItem(NSMenuItem.separator())

        statusBarMenu.addItem(
                withTitle: "Quit",
                action: #selector(AppDelegate.QuitAPP),
                keyEquivalent: "q")

//        print(titleList)

        if second! % 2 == 0 {
            timeCount = timeCount + 1
            if timeCount % interval == 0 {
                numberCount = numberCount + 1
            }
        }
//        print(second)
//        print(timeCount)
//        print(numberCount)
//        print(interval)
//        print(timeCount % interval)

        if numberCount == candidates.count {
            numberCount = 0
        }

        if titleList[candidates[numberCount]] != nil {
            let title = titleList[candidates[numberCount]]!
            update_buttom(title: title)
        }

        if timeCount >= candidates.count * interval {
            timeCount = 0
        }
//        print(titleString)
    }


    @objc func getData(symbol: String) {
        let url = "https://query1.finance.yahoo.com/v6/finance/quote?&symbols=\(symbol)&fields=regularMarketPrice,regularMarketChangePercent,shortName"
        let stocksURL = URL(string: url.urlEncoded())
        URLSession.shared.dataTask(with: stocksURL!) {
            (data, response, error) in
            if let error = error {
                print(error)
                return
            }
//            do {
            let dataString = String(data: data!, encoding: .utf8)!
            let dataDict = self.convertStringToDictionary(text: dataString)
            let quoteData = dataDict?["quoteResponse"] as! [String: Any]

            if let resultData = quoteData["result"] as? [[String: Any]],
               let result = resultData.first {
//                    let currency = result["currency"]
                let symbol = result["symbol"] as! String
                let regularMarketChangePercent = result["regularMarketChangePercent"] as! Double
                let regularMarketPrice = result["regularMarketPrice"] as! Double
//                    let shortName = result["shortName"] as! String

                let regularMarketPriceString = String(format: "%.2f", regularMarketPrice)
                var regularMarketChangePercentString = ""
                if regularMarketChangePercent > 0 {
                    regularMarketChangePercentString = "+" + String(format: "%.2f", regularMarketChangePercent) + "%"
                } else if regularMarketChangePercent == 0 {
                    regularMarketChangePercentString = String(format: "%.2f", regularMarketChangePercent) + "%"
                } else if regularMarketChangePercent < 0 {
                    regularMarketChangePercentString = "" + String(format: "%.2f", regularMarketChangePercent) + "%"
                }
                let string = "\(symbol) \(regularMarketPriceString) \(regularMarketChangePercentString)"
                self.titleList[symbol] = string
            }

//            } catch {
//                print(error)
//            }
//            print(symbol)


        }.resume()

    }

    @objc func QuitAPP(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }

    @objc func DoNothingAPP(_ sender: Any) {
    }

}

extension String {

    func urlEncoded() -> String {
        let encodeUrlString = self.addingPercentEncoding(withAllowedCharacters:
        .urlQueryAllowed)
        return encodeUrlString ?? ""
    }

    func urlDecoded() -> String {
        return self.removingPercentEncoding ?? ""
    }
}
