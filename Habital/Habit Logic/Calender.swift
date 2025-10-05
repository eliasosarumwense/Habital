//
//  Calender.swift
//  Habital
//
//  Created by Elias Osarumwense on 22.08.25.
//
import Foundation

enum AppCalendar {
    static let tz = TimeZone.current
    static var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = tz
        c.firstWeekday = 2 // Monday
        return c
    }()
}
