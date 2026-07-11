PYTHON = .venv/bin/python

convert:
	$(PYTHON) convert.py

part_2:
	$(PYTHON) run_cypher.py queries/part2_load.cypher

part_3:
	$(PYTHON) run_cypher.py queries/part3.cypher

part_4:
	$(PYTHON) run_cypher.py queries/part4_supernodes.cypher

part_5:
	$(PYTHON) run_cypher.py queries/part5_gds.cypher

all: convert part_2 part_3 part_4 part_5
