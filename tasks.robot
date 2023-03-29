*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Variables ***
${store_url}=               https://robotsparebinindustries.com/#/robot-order
${csv_file}=                https://robotsparebinindustries.com/orders.csv
${Global_Retry_Count}=      3
${Global_wait_time}=        3sec
${PDF_Folder}=              ${CURDIR}${/}output${/}receipts
${Img_Temp_Folder}=         ${CURDIR}${/}output${/}img


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Setup required Directories
    Open the robot order website
    ${orderdata}=    Download csv and read orders
    Click Element    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Set Test Variable    ${count}    ${0}

    FOR    ${order}    IN    @{orderdata}
        Log To Console    ${order}

        ${temp}=    Evaluate    ${count} + 1
        #IF    ${temp} < 5
        Fill the Form    ${order}
        TRY
            Wait Until Keyword Succeeds    ${Global_Retry_Count}    ${Global_wait_time}    Submit the Order
            ${recpt}=    Generate receipt    ${order}[Order number]
            Log To Console    ${recpt}
            ${rbt_img}=    Take Screenshot of robot    ${order}[Order number]
            Log To Console    ${rbt_img}
            Wait Until Keyword Succeeds    ${Global_Retry_Count}    ${Global_wait_time}
            ...    Embed image to receipt    ${recpt}    ${rbt_img}

            Wait Until Element Is Visible    //*[@id="order-another"]
            Wait Until Keyword Succeeds    ${Global_Retry_Count}    ${Global_wait_time}
            ...    Click Element    //*[@id="order-another"]
            Wait Until Element Is Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
            Wait Until Keyword Succeeds    ${Global_Retry_Count}    ${Global_wait_time}
            ...    Click Element    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
        EXCEPT
            Log To Console    Order no ${order}[Order number] could not be submitted
        END
        Set Test Variable    ${count}    ${temp}
        #ELSE
        #BREAK
        #END
    END
    Wait Until Keyword Succeeds    ${Global_Retry_Count}    ${Global_wait_time}
    ...    Package pdf into zip


*** Keywords ***
Open the robot order website
    Open Available Browser    ${store_url}
    Maximize Browser Window

Download csv and read orders
    Download    ${csv_file}    overwrite=True
    ${orderdata}=    Read table from CSV    orders.csv    header=True
    Log To Console    Found columns: ${orderdata.columns}
    RETURN    ${orderdata}

Fill the Form
    [Arguments]    ${order}
    Select From List By Value    //*[@id="head"]    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Element    preview

Submit the Order
    Click Element    order

Generate receipt
    [Arguments]    ${order number}
    Wait Until Element Is Visible    id:receipt
    ${rcpt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${rcpt_html}    ${PDF_Folder}${/}rcpt_${order number}.pdf
    RETURN    ${PDF_Folder}${/}rcpt_${order number}.pdf

Take Screenshot of robot
    [Arguments]    ${Order number}
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${Img_Temp_Folder}${/}${Order number}.PNG
    RETURN    ${Img_Temp_Folder}${/}${Order number}.PNG

Embed image to receipt
    [Arguments]    ${recpt}    ${rbt_img}
    Open Pdf    ${recpt}
    @{pdflist}=    Create List    ${rbt_img}
    Log To Console    ${pdflist}${SPACE}${pdflist}[0]
    TRY
        Add Files To Pdf    ${pdflist}    ${recpt}    ${True}
    EXCEPT
        Log to Console    Failed to add image in pdf
    END
    Close Pdf    ${recpt}

Package pdf into zip
    ${zip_file}=    Set Variable    ${CURDIR}${/}output${/}PDFArchive.zip
    Archive Folder With Zip    ${PDF_Folder}    ${zip_file}

Setup required Directories
    Create Directory    ${PDF_Folder}
    Create Directory    ${Img_Temp_Folder}
