In the `inventorywindow` script, in the `initialize_inventory_control` function, the `control.my_inventory = inv` is set directly. However, the ctrlinventorystackedcustom has a `set_inventory` function. We should evaluate if setting `control.my_inventory = inv` is desirable or if we should use set_inventory instead.

Same for 
```
LeftHandEquipmentSlot.my_inventory = inventory
RightHandEquipmentSlot.my_inventory = inventory
```
in the same script `inventorywindow`
