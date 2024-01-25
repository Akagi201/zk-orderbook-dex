use match_engine::parser::run_engine;

pub fn run_host(_instructions: Vec<String>) -> (Vec<String>, Vec<String>) {
    let instructions = vec![
        "INSERT,1,BTC,SELL,41000,10".to_string(), // sell 2
        "INSERT,2,BTC,SELL,40000,10".to_string(), // sell 1, needed input
        "INSERT,3,BTC,BUY,39000,10".to_string(),  // buy 1
        "INSERT,4,BTC,BUY,38000,10".to_string(),  // buy 2
        "INSERT,5,BTC,BUY,40000,20".to_string(),  // my order, needed input
    ];

    let result = run_engine(&instructions); // ["BTC,40000,10,5,2"] [symbol,price,volume,taker_order_id,maker_order_id]

    let input = vec![
        "INSERT,2,BTC,SELL,40000,10".to_string(), // sell 1, needed input
        "INSERT,5,BTC,BUY,40000,20".to_string(),  // my order, needed input
    ];
    (input, result)
}
