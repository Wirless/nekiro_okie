This is nekiro build 7.72 with tooltips / item rarities and frames use Rookie from otland 
https://otland.net/threads/tfs-1-5-7-4-rookieots.289065/


ALTER TABLE players
ADD COLUMN skill_farming int(10) unsigned NOT NULL DEFAULT 10,
ADD COLUMN skill_farming_tries bigint(20) unsigned NOT NULL DEFAULT 0;
