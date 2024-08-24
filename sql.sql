-- i think this is the sql for it idk idc

CREATE TABLE player_levels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL UNIQUE,
    steam_name VARCHAR(255) NOT NULL,
    level INT NOT NULL,
    xp INT NOT NULL,
    needxp INT NOT NULL
);
