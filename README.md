# Black Thursday

The goal of the project was to build a sales engine to that could read in and store data for a hypothetical online store.
With this base engine, data analysis was performed with an eye towards business logic.

## Installation

1. Get the URL for cloning
2. Move to the directory you want it to be located and do `git clone <cloning url>`
3. Install the gems with `bundle install`
4. You're ready to go!

## Usage

Currently the program is not used much other than against tests. The easiest way to use it would be to open it in IRB/pry

1. Open your favorite Ruby REPL
2. Require './lib/sales_engine'
3. Create a new sales engine instance
4. Load CSVs into sales engine using #from_csv
5. (if analytics are desired) Require './lib/sales_analyst'
6. Create a new instance of sales analyst, initialized with the sales engine

## Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request :D

## Credits

This project was a joint venture of Nate Anderson and Jean Joeris. It was made possible by all the wonderful teachers at Turing School of Software and Design.

## License

This piece of software is distibuted under the MIT License
