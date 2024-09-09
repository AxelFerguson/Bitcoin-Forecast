The add_stock_flow_trigger file is the actual trigger utilized to insert rows into a table with the relevant cleaned and processed blockchain information.

The select_clean_blockchain file generates the same results as the add_stock_flow_trigger, but is written with CTE's making the script easier to follow and understand.

The create_view_bitcoinpricesf file generates a view to pull only the relevant information from both the stock flow and price tables.
