//
//  PickerFieldsDataHelper.swift
//  PickerDataHelper
//
//  Created by Allan Alves on 28/10/16.
//  Copyright © 2016 Allan Alves. All rights reserved.
//

import UIKit

@objc protocol PickerFieldsDataHelperDelegate: class {
    @objc optional func pickerFieldsDataHelper(dataHelper: PickerDataHelper, didSelectObject selectedObject: AnyObject?, withTitle title: String?)
}

@objc class PickerDataHelper: NSObject {
    var pickerView: UIPickerView?
    var datePicker: UIDatePicker?
    var textField: UITextField?
    var isDateType: Bool
    var titles = [String]()
    var objects = [AnyObject]()
    var selectedObject: AnyObject?
    
    init(textField: UITextField, isDateType: Bool) {
        let pickerView = UIPickerView()
        self.pickerView = pickerView
        self.textField = textField
        self.isDateType = isDateType
    }
}

class PickerFieldsDataHelper: NSObject, PickerFieldsDataHelperDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    weak var delegate: PickerFieldsDataHelperDelegate?
    var dataHelpers = [PickerDataHelper]()
    
    var doneButtonTitle = "OK"
    
    //Show first item with nil object
    var useDefaultFirstItem = true
    var initWithDefaultFirstItemSelected = true //if useDefaultFirstItem is true
    var defaultFirstItemTitle = "Select..." //Use if useDefaultFirstItem is true
    
    //Date Type
    var dateFormat = "dd/MM/yyyy"
    var initWithTodayDate = false
    
    //Nav Item
    var showPlaceholderAsTitle = false
    
    //MARK: - Initialization -
    
    func addDataHelpers(textFields: [UITextField], isDateType: Bool) {
        for textField in textFields {
            addDataHelper(textField, isDateType: isDateType)
        }
    }
    
    func addDataHelper(textField: UITextField, isDateType: Bool) {
        let dataHelper = PickerDataHelper(textField: textField, isDateType: isDateType)
        dataHelper.isDateType = isDateType
        
        if isDateType {
            let datePicker = UIDatePicker()
            datePicker.datePickerMode = .Date
            dataHelper.datePicker = datePicker
            textField.inputView = datePicker
            
            if initWithTodayDate {
                datePicker.date = NSDate()
                refreshDate(dataHelper)
            }
        } else {
            //Picker View
            let pickerView = UIPickerView()
            dataHelper.pickerView = pickerView
            
            //Set Delegate, DataSource & Correspondent TextFields
            pickerView.delegate = self
            pickerView.dataSource = self
            //TextField InputView
            textField.inputView = pickerView
            
            //Add first default item if needed
            if useDefaultFirstItem {
                dataHelper.titles.append(defaultFirstItemTitle)
                if initWithDefaultFirstItemSelected {
                    textField.text = defaultFirstItemTitle
                }
            }
        }
        //Input Accessory View
        addToolBarPickerViews(doneButtonTitle, textField: textField)
        
        dataHelpers.append(dataHelper)
        refreshAllPickers()
    }
    
    func dataHelper(textField: UITextField) -> PickerDataHelper? {
        for item in dataHelpers {
            if textField == item.textField {
                return item
            }
        }
        return nil
    }
    
    //MARK: - Content -
    
    func addTitleAndObjectInDataHelper(textField: UITextField, title: String, object: AnyObject) {
        if let dataHelper = dataHelper(textField) {
            dataHelper.titles.append(title)
            dataHelper.objects.append(object)
            refreshAllPickers()
        }
    }
    
    //Return selected object for given textfield
    func selectedObjectForTextField(textField: UITextField) -> AnyObject? {
        if let dataHelper = dataHelper(textField) {
            if let object = dataHelper.selectedObject {
                return object
            }
        }
        return nil
    }
    
    //MARK: - Picker Views -
    
    func refreshAllPickers() {
        for dataHelper in dataHelpers {
            if let pickerView = dataHelper.pickerView {
                pickerView.reloadAllComponents()
            }
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        for dataHelper in dataHelpers {
            if dataHelper.pickerView == pickerView {
                return dataHelper.titles[row]
            }
        }
        return "❔"
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        for dataHelper in dataHelpers {
            if dataHelper.pickerView == pickerView {
                return dataHelper.titles.count
            }
        }
        return 0
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    //MARK: - Other -
    
    func selectDate(date: NSDate, textField: UITextField) {
        if let dataHelper = dataHelper(textField) {
            if dataHelper.isDateType {
                if let datePicker = dataHelper.datePicker {
                    datePicker.date = date
                    refreshDate(dataHelper)
                }
            }
        }
    }
    
    func clearAllFields() {
        for dataHelper in dataHelpers {
            if let textField = dataHelper.textField {
                if dataHelper.isDateType {
                    //Date Type
                    if initWithTodayDate { //Init With Today
                        if let datePicker = dataHelper.datePicker {
                            datePicker.date = NSDate()
                            refreshDate(dataHelper)
                        } else {
                            textField.text = ""
                        }
                    }
                    //Normal Type
                } else {
                    textField.text = ""
                    if useDefaultFirstItem { //Init With First Default Title
                        if initWithDefaultFirstItemSelected {
                            textField.text = defaultFirstItemTitle
                        }
                    }
                }
            }
        }
    }
    
    //MARK: - Input Accessory View -
    
    //Add input accessory view with done button
    func addToolBarPickerViews(title : String, textField : UITextField) {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.Default
        toolBar.translucent = true
        toolBar.tintColor = Color.black().colorWithAlphaComponent(0.1)
        toolBar.sizeToFit()
        
        let closeButton = UIBarButtonItem(title: title, style: .Done, target: self, action: #selector(self.closePicker))
        closeButton.tintColor = Color.blueCustodiaButtons()
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, closeButton], animated: false)
        toolBar.userInteractionEnabled = true
        
        textField.inputAccessoryView = toolBar
    }
    
    //Set selected date as selected object, and textfield title
    func refreshDate(dataHelper: PickerDataHelper) {
        if let datePicker = dataHelper.datePicker {
            dataHelper.selectedObject = datePicker.date
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = dateFormat
            if let textField = dataHelper.textField {
                textField.text = dateFormatter.stringFromDate(datePicker.date)
            }
        }
    }
    
    //MARK: - Actions -
    
    //Hide keyboard, set selected object and set title of textfield
    func closePicker() {
        //TDOO: Get selected picker item and set text of textfield
        for dataHelper in dataHelpers {
            if let textField = dataHelper.textField {
                if textField.isFirstResponder() {
                    textField.superview?.endEditing(true) //Hide Keyboard
                    if dataHelper.isDateType {
                        refreshDate(dataHelper)
                    } else {
                        if let pickerView = dataHelper.pickerView {
                            let row = pickerView.selectedRowInComponent(0) //Get Index
                            if row < dataHelper.titles.count && row > -1 {
                                let title = dataHelper.titles[row] //Get Title
                                textField.text = title
                                
                                if useDefaultFirstItem {
                                    //Use nil as default - if index given is not in objects/titles range
                                    dataHelper.selectedObject = nil
                                    if row > 0 && row < dataHelper.titles.count {
                                        dataHelper.selectedObject = dataHelper.objects[row-1]
                                    }
                                } else {
                                    if row > -1 && row < dataHelper.titles.count {
                                        dataHelper.selectedObject = dataHelper.objects[row]
                                    }
                                }
                                //When user taps the done button to select an option
                                self.delegate?.pickerFieldsDataHelper?(dataHelper,
                                                                       didSelectObject: dataHelper.selectedObject,
                                                                       withTitle: title)
                            }
                        }
                    }
                }
            }
        }
    }
    
}







