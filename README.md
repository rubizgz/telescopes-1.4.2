# Dependencies
* **oxmysql**
* **ox_lib**
* **ox_target**
* **ox_inventory**

# Inventory Items Setup
Add the following lines into your ox_inventory/data/items.lua

```lua
    ['telescope'] = {
        label = 'Telescope',
        weight = 1500,
        stack = false,
        close = true,
        client = {
            export = 'telescopes.UseTelescope'
        }
    },
    ['telescope2'] = {
        label = 'Telescope',
        weight = 1500,
        stack = false,
        close = true,
        client = {
            export = 'telescopes.UseTelescope'
        }
    },
    ['telescope3'] = {
        label = 'Telescope',
        weight = 1500,
        stack = false,
        close = true,
        client = {
            export = 'telescopes.UseTelescope'
        }
    },
    ['telescope4'] = {
        label = 'Telescope',
        weight = 1500,
        stack = false,
        close = true,
        client = {
            export = 'telescopes.UseTelescope'
        }
    },
```

# Database Setup
Execute the following SQL query in your database manager (MariaDB is recommended)

```sql
CREATE TABLE IF NOT EXISTS `telescopes` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `coords` LONGTEXT NOT NULL,
    `telescope` VARCHAR(50) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`) USING BTREE
);
```