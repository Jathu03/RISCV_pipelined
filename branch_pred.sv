module branch_pred (
    input logic clk, rstn, branch_taken, is_branch_prev,
    input logic [31:0] epc, fpc,
    output logic pred
);

    // Global history register (stores the last few branch outcomes)
    logic [7:0] global_history;  // 8-bit global history register for branch outcomes
    logic [1:0] global_prediction; // 2-bit prediction from global history
    logic [2:0] global_index;  // Index for global history lookup (derived from global history)

    // 2-bit saturating counter table for branch prediction
    logic [1:0] prediction_table [7:0];

    // Generate global index from global history
    assign global_index = global_history[7:5];  // Use the upper 3 bits for the index (or a subset of bits)
    assign global_prediction = prediction_table[global_index];

    // Branch prediction output
    assign pred = (global_prediction == 2'b00 || global_prediction == 2'b01) ? 1'b0 : 1'b1;

    // Always block to update global history and prediction table
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            // Reset the global history and prediction table
            global_history <= 8'b0; // Reset history to zero
            for (int i = 0; i < 8; i++) begin
                prediction_table[i] <= 2'b11; // Initialize to strongly taken
            end
        end else if (is_branch_prev) begin
            // Update the global history with the new branch outcome
            global_history <= {global_history[6:0], branch_taken}; // Shift in the latest branch outcome

            // Update the prediction table using saturating counters
            if (branch_taken) begin
                // Increment the counter if the branch was taken, but not beyond 2'b11 (strongly taken)
                prediction_table[global_index] <= (prediction_table[global_index] == 2'b11) ? 2'b11 : prediction_table[global_index] + 1;
            end else begin
                // Decrement the counter if the branch was not taken, but not below 2'b00 (strongly not taken)
                prediction_table[global_index] <= (prediction_table[global_index] == 2'b00) ? 2'b00 : prediction_table[global_index] - 1;
            end
        end
    end

endmodule
