import re
import os
import time
import psutil
import subprocess

output_file = "/srv/avorion/systemstatus.log"
rcon_connect = "/usr/bin/rcon -c /srv/avorion/rconhostfile -s ds9server status"

def setup_regex_dict():
	regex_matches = {}
	regex_matches["online_players"] = re.compile(r"^(\d+) players online, in \d+ sectors$")
	regex_matches["loaded_players"] = re.compile(r"^(\d+) players in memory, (\d+) registered$")
	regex_matches["faction_info"]   = re.compile(r"^(\d+) factions in memory, (\d+) registered$")
	regex_matches["sector_info"]    = re.compile(r"^(\d+) sectors in memory, (\d+) sectors in total$")
	regex_matches["script_ram"]     = re.compile(r"^Sectors Updated: (\d+)$")
	regex_matches["avg_update"]     = re.compile(r"^avg. update: (\d+) ms$")
	regex_matches["max_update"]     = re.compile(r"^max. update: (\d+) ms$")
	regex_matches["min_update"]     = re.compile(r"^min. update: (\d+) ms$")
	regex_matches["game_load"]      = re.compile(r"^avg. server load: (\d+\.?(\d+)?)%")
	return regex_matches

def get_server_statistics():
	server_status = {
		"epoch":                int(time.time()),
		"RAM":                  {},
		"CPU":                  {},
		"LOAD":                 {},
		"avorion": {
			"skipped":          False, ## Skip if there is a backup running
			"hang":             False,
			"game_load":        0,
			"avg_update":       0,
			"max_update":       0,
			"min_update":       0,
			"script_ram_usage": 0,
			"online_players":   0,
			"loaded_players":   0,
			"total_players":    0,
			"loaded_factions":  0,
			"total_factions":   0,
			"loaded_sectors":   0,
			"total_sectors":    0,
			"updated_sectors":  0,
			}
		}
	server_status["CPU"]["count"] = psutil.cpu_count()
	server_status["CPU"].update(psutil.cpu_stats()._asdict())
	server_status["CPU"].update(psutil.cpu_times_percent()._asdict())
	server_status["RAM"].update(psutil.virtual_memory()._asdict())do not cry, l


def get_avorion_response(cmdstring):
    response = ""
    try:
        response = subprocess([cmdstring])
    except:
        return False
    if len(response) < 200:
        return False
    return response

def parse_avorion_response(reg, resp, stat):
	print(reg["online_players".](resp).group())

def serialize_server_data():
	os.Exit(0)

def main(skipped=False):
	stat["avorion"]["skipped"] = skipped
    stat = get_server_statistics()
	if not skipped:
		reg = setup_regex_dict()
		resp = get_avorion_response(rcon_connect)
		if resp == False:
			stat["avorion"]["hang"] = True
			os.Exit(1)
		if parse_avorion_response(reg, resp, stat) == False:
			stat["avorion"]["hang"] = True

if __name__ == '__main__':
	skipped = check_backup_running()
    main(skipped)
