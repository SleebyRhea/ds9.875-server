import re
import os
import time
import psutil
import subprocess

output_file = "/srv/avorion/systemstatus.log"
rcon_hostfile = "/srv/avorion/rconhostfile"
rcon_hostname = "ds9server"
rcon_connect = "/usr/local/bin/rcon"

def check_backup_running():
    return False

def setup_regex_dict():
	regex_matches = {}
	regex_matches["online_players"] = "^(\d+) players online, in \d+ sectors\n"
	regex_matches["loaded_players"] = "\n(\d+) players in memory, (\d+) registered\n"
	regex_matches["faction_info"]   = "\n(\d+) factions in memory, (\d+) registered\n"
	regex_matches["sector_info"]    = "\n(\d+) sectors in memory, (\d+) sectors in total\n"
	regex_matches["script_ram"]     = "\nSectors Updated: (\d+)\n"
	regex_matches["avg_update"]     = "\navg. update: (\d+) ms\n"
	regex_matches["max_update"]     = "\nmax. update: (\d+) ms\n"
	regex_matches["min_update"]     = "\nmin. update: (\d+) ms\n"
	regex_matches["game_load"]      = "\navg. server load: (\d+\.?(\d+)?)%"
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
	server_status["RAM"].update(psutil.virtual_memory()._asdict())
	return server_status

def get_avorion_response(cmdstring):
	response = ""
	try:
		response = subprocess.run([rcon_connect, "-c", rcon_hostfile, "-s", rcon_hostname, "status"],
			stdout=subprocess.PIPE,encoding="UTF-8", timeout=30)
	except subprocess.TimeoutExpired:
		print("Timeout exceeded on server connect. Assuming hang.")
		return False
	except subprocess.CalledProcessError:
		print("Failed to connect to the server")
		return False
	if len(response.stdout) < 200:
		return False
	print(response.stdout)
	return response.stdout

def parse_avorion_response(reg, resp, stat):
	stat["online_players"] = re.search(reg["online_players"], resp).group(1)
	stat["script_ram"] = re.search(reg["script_ram"], resp).group(1)
	stat["avg_update"] = re.search(reg["avg_update"], resp).group(1)
	stat["max_update"] = re.search(reg["max_update"], resp).group(1)
	stat["min_update"] = re.search(reg["min_update"], resp).group(1)
	stat["game_load"] = re.search(reg["game_load"], resp).group(1)

	m = re.search(reg["loaded_players"], resp)
	stat["loaded_players"] = m.group(1)
	stat["total_players"] = m.group(2)

	m = re.search(reg["faction_info"], resp)
	stat["loaded_factions"] = m.group(1)
	stat["total_factions"] = m.group(2)

	m = re.search(reg["sector_info"], resp)
	stat["loaded_sectors"] = m.group(1)
	stat["total_sectors"] = m.group(2)

def serialize_server_data():
	return True

def main(skipped=False):
	stat = get_server_statistics()
	stat["avorion"]["skipped"] = skipped
	if not skipped:
		reg = setup_regex_dict()
		resp = get_avorion_response(rcon_connect)
		if resp == False:
			stat["avorion"]["hang"] = True
			print("Failed")
			return False
		if parse_avorion_response(reg, resp, stat) == False:
			stat["avorion"]["hang"] = True
			print("Failed")
			return False

if __name__ == '__main__':
	main(check_backup_running())

