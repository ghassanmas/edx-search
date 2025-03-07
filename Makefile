.PHONY: clean quality requirements validate test test-python quality-python

clean:
	find . -name '__pycache__' -exec rm -rf {} +
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +	
	coverage erase
	rm -rf coverage htmlcov
	rm -fr build/
	rm -fr dist/
	rm -fr *.egg-info

quality-python: ## Run python linters
	pycodestyle --config=.pep8 manage.py search edxsearch/settings.py setup.py
	pylint --rcfile=pylintrc manage.py search edxsearch/settings.py setup.py

quality: quality-python

requirements:
	pip install -qr requirements/pip.txt
	pip install -r requirements/dev.txt

validate: clean
	tox

test.start_elasticsearch:
	docker-compose up -d

test.stop_elasticsearch:
	docker-compose stop

test_with_es: clean test.start_elasticsearch
	coverage run --source='.' manage.py test
	make test.stop_elasticsearch

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	pip install -qr requirements/pip-tools.txt
	# Make sure to compile files after any other files they include!
	pip-compile --rebuild --allow-unsafe --rebuild -o requirements/pip.txt requirements/pip.in
	pip-compile --rebuild --upgrade -o requirements/pip-tools.txt requirements/pip-tools.in
	pip install -qr requirements/pip.txt
	pip install -qr requirements/pip-tools.txt
	pip-compile --rebuild --upgrade -o requirements/base.txt requirements/base.in
	pip-compile --rebuild --upgrade -o requirements/testing.txt requirements/testing.in
	pip-compile --rebuild --upgrade -o requirements/quality.txt requirements/quality.in
	pip-compile --rebuild --upgrade -o requirements/ci.txt requirements/ci.in
	pip-compile --rebuild --upgrade -o requirements/dev.txt requirements/dev.in
	# Let tox control the Django version for tests
	sed '/^[dD]jango==/d' requirements/testing.txt > requirements/testing.tmp
	mv requirements/testing.tmp requirements/testing.txt

test-python: clean ## run tests using pytest and generate coverage report
	pytest

test: test-python ## run tests and generate coverage report
