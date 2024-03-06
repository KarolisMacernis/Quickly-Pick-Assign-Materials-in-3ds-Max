-- Initialize the pickedMaterials array outside of the function
-- This array will store the materials picked by the user
-- Global scope is necessary as this array needs to be accessed by multiple functions
global pickedMaterials = #()

-- Initialize numSlots to a default value
-- This variable represents the number of material slots in the dialog
-- It's global because it needs to be accessed and modified by multiple functions
global numSlots = 5

-- Define the function that creates the window
-- This function takes the number of material slots as a parameter
global createDialogWithSlots = fn createDialogWithSlots numMaterialSlots =
(

    -- Store the current materials in a temporary array
    -- This is done to preserve the materials when the pickedMaterials array is resized
    tempMaterials = deepcopy pickedMaterials

    -- Resize the pickedMaterials array to match the number of material slots
    -- This is done to ensure that the array has the correct size
    pickedMaterials.count = numMaterialSlots

    -- Copy the materials from the temporary array back to the pickedMaterials array
    -- This is done to restore the materials after the pickedMaterials array has been resized
    for i = 1 to tempMaterials.count do
    (
        pickedMaterials[i] = tempMaterials[i]
    )

    -- Create an array to store the material labels
    -- Each label will display the name of the picked material for a slot
    global materialLabels = for i = 1 to numMaterialSlots collect (undefined)

    -- Create the pick function with an index parameter
    -- This function allows the user to pick a material for a specific slot
    global pickMaterialFunction = fn pickMaterialFunction i =
    (
        pickedObject = pickObject()
        if pickedObject != undefined and pickedObject.material != undefined then
        (
            pickedMaterials[i] = pickedObject.material
            materialLabels[i].text = "Selected Material: " + pickedMaterials[i].name
        )
        else
        (
            print "No material picked."
            pickedMaterials[i] = undefined -- Clear the material slot
            materialLabels[i].text = "No material selected."
        )
    )

    -- Create the assign function with an index parameter
    -- This function allows the user to assign the picked material for a specific slot to the selected objects
    global assignMaterialFunction = fn assignMaterialFunction i =
    (
        if pickedMaterials[i] != undefined then
        (
            undo "Assign Material" on
            (
                for obj in selection do
                (
                    obj.material = pickedMaterials[i]
                    print ("Assigned Material: " + pickedMaterials[i].name + " to Object: " + obj.name)
                )
            )
        )
        else
            print "No material picked."
    )

    -- Create macroScripts for each pick function
    -- These macroScripts allow the pick functions to be called from the user interface
    -- We're using execute to dynamically create a macroScript for each material slot
    for i = 1 to numMaterialSlots do
    (
        execute ("macroScript PickMaterial" + i as string + " category:\"Custom Scripts\" \n" +
        "(\n" +
        "    pickMaterialFunction " + i as string + "\n" +
        ")")
    )

    -- Create macroScripts for each assign function
    -- These macroScripts allow the assign functions to be called from the user interface
    for i = 1 to numMaterialSlots do
    (
        execute ("macroScript AssignPickedMaterial" + i as string + " category:\"Custom Scripts\" \n" +
        "(\n" +
        "    assignMaterialFunction " + i as string + "\n" +
        ")")
    )

    -- Create a string that contains the rollout definition
    -- The height of the rollout is calculated based on the number of material slots
    -- We're constructing the rollout definition as a string so that we can dynamically add elements based on the number of material slots
    rolloutDefinition = "rollout materialRollout \"Pick/Assign Materials\" width:440 height:" + ((numMaterialSlots * 65) + 55) as string + "\n(\n"

    -- Add the Recreate button to the rollout definition
    -- This button will allow the user to recreate the dialog with a different number of material slots
    rolloutDefinition += "    button recreateButton \"Apply\" pos:[151,16] width:80 height:20\n"

    -- Add the recreate button pressed event to the rollout definition
    -- When the button is pressed, the current dialog is destroyed and a new one is created with the current number of slots
    rolloutDefinition += "    on recreateButton pressed do\n    (\n        destroyDialog materialRollout\n        createDialogWithSlots numSlots\n    )\n"

    -- Add the group boxes, buttons, and labels to the rollout definition
    -- Each material slot has a group box, a pick button, an assign button, and a label
    for i = 1 to numMaterialSlots do
    (
        rolloutDefinition += "    groupBox materialSlot" + i as string 
        rolloutDefinition += " \"Material Slot " + i as string 
        rolloutDefinition += "\" pos:[10," + ((i-1)*65+55) as string 
        rolloutDefinition += "] width:420 height:55\n"

        rolloutDefinition += "    button pickMaterialButton" + i as string 
        rolloutDefinition += " \"Pick New\" pos:[20," + ((i-1)*65+77) as string 
        rolloutDefinition += "] width:80 height:20\n"

        rolloutDefinition += "    button assignMaterialButton" + i as string 
        rolloutDefinition += " \"Assign Material\" pos:[110," + ((i-1)*65+77) as string 
        rolloutDefinition += "] width:100 height:20\n"

        rolloutDefinition += "    label materialLabel" + i as string 
        rolloutDefinition += " \"No material selected.\" pos:[220," + ((i-1)*65+81) as string 
        rolloutDefinition += "] width:200 height:20\n"
    )

    -- Add the input box to the rollout definition
    -- This input box allows the user to change the number of material slots
    rolloutDefinition += "    spinner numSlotsSpinner \"Number of Slots:\" pos:[81,18] width:60 height:30 range:[1,100," 
    rolloutDefinition += numSlots as string + "] type:#integer\n"

    -- Add the spinner changed event to the rollout definition
    -- When the value of the spinner changes, the number of slots is updated and a message is printed
    rolloutDefinition += "    on numSlotsSpinner changed val do\n    (\n" 
    rolloutDefinition += "        numSlots = val\n" 
    rolloutDefinition += "        print (\"Number of slots changed to: \" + numSlots as string)\n    )\n"

    -- Add the open event to the rollout definition
    -- When the rollout is opened, the material labels are updated based on the current picked materials
    -- This is necessary to reflect any pre-existing picked materials when the dialog is recreated
    rolloutDefinition += "    on materialRollout open do\n    (\n        materialLabels = #("

    for i = 1 to numMaterialSlots do
    (
        rolloutDefinition += "materialLabel" + i as string
        if i != numMaterialSlots then
            rolloutDefinition += ", "
    )

    rolloutDefinition += ")\n"

    -- Add code to update the material labels
    -- If a material has been picked for a slot, the label displays the name of the material
    -- If no material has been picked, the label displays "No material selected."
    for i = 1 to numMaterialSlots do
    (
        if pickedMaterials[i] != undefined then
        (
            rolloutDefinition += "        materialLabels[" + i as string + "].text = \"Selected Material: \" + pickedMaterials[" + i as string + "].name\n"
        )
        else
        (
            rolloutDefinition += "        materialLabels[" + i as string + "].text = \"No material selected.\"\n"
        )
    )

    rolloutDefinition += "    )\n"

    -- Add the button pressed events to the rollout definition
    -- When the pick button is pressed, the pick function is called for the corresponding slot
    -- When the assign button is pressed, the assign function is called for the corresponding slot
    for i = 1 to numMaterialSlots do
    (
        rolloutDefinition += "    on pickMaterialButton" + i as string + " pressed do (pickMaterialFunction " + i as string + ")\n"
        rolloutDefinition += "    on assignMaterialButton" + i as string + " pressed do (assignMaterialFunction " + i as string + ")\n"
    )

    -- Close the rollout definition
    -- This marks the end of the rollout definition string
    rolloutDefinition += ")"

    -- Execute the rolloutDefinition string to create a rollout
    materialRollout = execute rolloutDefinition

    -- Create a new dialog with the rollout
    -- This displays the rollout to the user
    createDialog materialRollout
)

-- Call the function with the desired number of material slots
-- This creates and displays the dialog with the initial number of slots
createDialogWithSlots numSlots