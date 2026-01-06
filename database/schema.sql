-- =============================================
-- GAMBLING WEBSITE DATABASE SCHEMA
-- =============================================

-- 1. USERS TABLE
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20),
    full_name VARCHAR(100),
    date_of_birth DATE,
    country VARCHAR(50),
    account_status ENUM('active', 'suspended', 'banned', 'pending_verification') DEFAULT 'active',
    email_verified BOOLEAN DEFAULT FALSE,
    phone_verified BOOLEAN DEFAULT FALSE,
    kyc_status ENUM('not_verified', 'pending', 'verified', 'rejected') DEFAULT 'not_verified',
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    last_ip_address VARCHAR(45),
    referral_code VARCHAR(20) UNIQUE,
    referred_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (referred_by) REFERENCES users(user_id) ON DELETE SET NULL,
    INDEX idx_email (email),
    INDEX idx_username (username),
    INDEX idx_referral_code (referral_code)
);

-- 2. WALLET TABLE
CREATE TABLE wallets (
    wallet_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    main_balance DECIMAL(15, 2) DEFAULT 0.00,
    bonus_balance DECIMAL(15, 2) DEFAULT 0.00,
    locked_balance DECIMAL(15, 2) DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    total_deposits DECIMAL(15, 2) DEFAULT 0.00,
    total_withdrawals DECIMAL(15, 2) DEFAULT 0.00,
    total_wagered DECIMAL(15, 2) DEFAULT 0.00,
    last_transaction_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);

-- 3. DEPOSITS TABLE
CREATE TABLE deposits (
    deposit_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method VARCHAR(50),
    payment_gateway_txn_id VARCHAR(100),
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
    payment_proof_url VARCHAR(255),
    deposit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_date TIMESTAMP NULL,
    processed_by INT,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES admins(admin_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_deposit_date (deposit_date)
);

-- 4. WITHDRAWALS TABLE
CREATE TABLE withdrawals (
    withdrawal_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    withdrawal_method VARCHAR(50),
    account_details TEXT,
    status ENUM('pending', 'processing', 'completed', 'rejected', 'cancelled') DEFAULT 'pending',
    request_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_date TIMESTAMP NULL,
    processed_by INT,
    rejection_reason TEXT,
    transaction_reference VARCHAR(100),
    fees_charged DECIMAL(10, 2) DEFAULT 0.00,
    notes TEXT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (processed_by) REFERENCES admins(admin_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_request_date (request_date)
);

-- 5. GAMES TABLE
CREATE TABLE games (
    game_id INT PRIMARY KEY AUTO_INCREMENT,
    game_name VARCHAR(100) NOT NULL,
    game_type ENUM('slots', 'roulette', 'dice', 'cards', 'lottery', 'sports', 'other'),
    provider VARCHAR(50),
    description TEXT,
    thumbnail_url VARCHAR(255),
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    min_bet DECIMAL(10, 2) DEFAULT 1.00,
    max_bet DECIMAL(10, 2) DEFAULT 10000.00,
    rtp_percentage DECIMAL(5, 2),
    popularity_score INT DEFAULT 0,
    category_tags VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_game_type (game_type),
    INDEX idx_status (status),
    INDEX idx_popularity (popularity_score)
);

-- 6. GAME SESSIONS/BETS TABLE
CREATE TABLE game_sessions (
    session_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    game_id INT NOT NULL,
    bet_amount DECIMAL(15, 2) NOT NULL,
    payout_amount DECIMAL(15, 2) DEFAULT 0.00,
    result ENUM('win', 'loss', 'draw') NOT NULL,
    game_data JSON,
    session_start TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_end TIMESTAMP NULL,
    ip_address VARCHAR(45),
    device_info VARCHAR(255),
    rng_seed VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_game_id (game_id),
    INDEX idx_session_start (session_start),
    INDEX idx_result (result)
);

-- 7. TRANSACTIONS TABLE (Master Ledger)
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    transaction_type ENUM('deposit', 'withdrawal', 'bet', 'win', 'bonus', 'refund', 'fee', 'adjustment'),
    amount DECIMAL(15, 2) NOT NULL,
    balance_before DECIMAL(15, 2),
    balance_after DECIMAL(15, 2),
    related_id INT,
    related_type VARCHAR(50),
    status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'completed',
    description VARCHAR(255),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_type (transaction_type),
    INDEX idx_date (transaction_date)
);

-- 8. BONUSES/PROMOTIONS TABLE
CREATE TABLE bonuses (
    bonus_id INT PRIMARY KEY AUTO_INCREMENT,
    bonus_name VARCHAR(100) NOT NULL,
    bonus_type ENUM('welcome', 'deposit_match', 'free_spins', 'cashback', 'referral', 'loyalty', 'reload'),
    bonus_value DECIMAL(10, 2),
    bonus_percentage DECIMAL(5, 2),
    wagering_requirement INT DEFAULT 1,
    min_deposit DECIMAL(10, 2),
    max_bonus DECIMAL(10, 2),
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP NULL,
    status ENUM('active', 'expired', 'inactive') DEFAULT 'active',
    terms_conditions TEXT,
    eligible_users ENUM('new', 'existing', 'vip', 'all') DEFAULT 'all',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_type (bonus_type)
);

-- 9. USER BONUSES TABLE
CREATE TABLE user_bonuses (
    user_bonus_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bonus_id INT NOT NULL,
    bonus_amount DECIMAL(15, 2) NOT NULL,
    wagering_requirement DECIMAL(15, 2),
    wagered_amount DECIMAL(15, 2) DEFAULT 0.00,
    status ENUM('active', 'completed', 'expired', 'cancelled') DEFAULT 'active',
    received_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expiry_date TIMESTAMP NULL,
    completed_date TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (bonus_id) REFERENCES bonuses(bonus_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status)
);

-- 10. KYC DOCUMENTS TABLE
CREATE TABLE kyc_documents (
    kyc_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    document_type ENUM('id_card', 'passport', 'drivers_license', 'address_proof', 'selfie'),
    document_number VARCHAR(50),
    document_url VARCHAR(255),
    selfie_url VARCHAR(255),
    submission_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verification_status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    verified_by INT,
    verification_date TIMESTAMP NULL,
    rejection_reason TEXT,
    document_expiry_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (verified_by) REFERENCES admins(admin_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (verification_status)
);

-- 11. SUPPORT TICKETS TABLE
CREATE TABLE support_tickets (
    ticket_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    subject VARCHAR(200) NOT NULL,
    category ENUM('account', 'deposit', 'withdrawal', 'game_issue', 'bonus', 'technical', 'other'),
    priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('open', 'in_progress', 'waiting_for_user', 'resolved', 'closed') DEFAULT 'open',
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    assigned_to INT,
    resolved_date TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES admins(admin_id) ON DELETE SET NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_priority (priority)
);

-- 12. TICKET MESSAGES TABLE
CREATE TABLE ticket_messages (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    ticket_id INT NOT NULL,
    sender_id INT NOT NULL,
    sender_type ENUM('user', 'admin') NOT NULL,
    message_content TEXT NOT NULL,
    attachments JSON,
    message_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (ticket_id) REFERENCES support_tickets(ticket_id) ON DELETE CASCADE,
    INDEX idx_ticket_id (ticket_id),
    INDEX idx_sender (sender_id, sender_type)
);

-- 13. ADMINS/STAFF TABLE
CREATE TABLE admins (
    admin_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    role ENUM('super_admin', 'finance_manager', 'support_agent', 'game_manager', 'kyc_verifier') NOT NULL,
    permissions JSON,
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- 14. AUDIT LOGS TABLE
CREATE TABLE audit_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    admin_id INT,
    user_type ENUM('user', 'admin'),
    action_type VARCHAR(50) NOT NULL,
    action_details JSON,
    ip_address VARCHAR(45),
    device_info VARCHAR(255),
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_admin (admin_id),
    INDEX idx_action (action_type),
    INDEX idx_date (log_date)
);

-- 15. RESPONSIBLE GAMING SETTINGS TABLE
CREATE TABLE responsible_gaming_settings (
    setting_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    daily_deposit_limit DECIMAL(10, 2),
    weekly_deposit_limit DECIMAL(10, 2),
    monthly_deposit_limit DECIMAL(10, 2),
    daily_loss_limit DECIMAL(10, 2),
    session_time_limit INT,
    self_exclusion_status BOOLEAN DEFAULT FALSE,
    self_exclusion_start DATE,
    self_exclusion_end DATE,
    reality_check_interval INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
);

-- 16. NOTIFICATIONS TABLE
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    type ENUM('deposit_success', 'withdrawal_approved', 'bonus_credited', 'game_win', 'kyc_update', 'system_alert'),
    title VARCHAR(100),
    message TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    notification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action_url VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_read (is_read),
    INDEX idx_date (notification_date)
);

-- 17. REFERRALS TABLE
CREATE TABLE referrals (
    referral_id INT PRIMARY KEY AUTO_INCREMENT,
    referrer_user_id INT NOT NULL,
    referred_user_id INT NOT NULL,
    referral_code VARCHAR(20),
    referral_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    referral_bonus_earned DECIMAL(10, 2) DEFAULT 0.00,
    status ENUM('pending', 'completed') DEFAULT 'pending',
    FOREIGN KEY (referrer_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (referred_user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_referrer (referrer_user_id),
    INDEX idx_referred (referred_user_id)
);

-- 18. SESSION MANAGEMENT TABLE
CREATE TABLE user_sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id INT NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address VARCHAR(45),
    device_info VARCHAR(255),
    login_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    logout_date TIMESTAMP NULL,
    status ENUM('active', 'expired', 'logged_out') DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_token (session_token),
    INDEX idx_status (status)
);

-- 19. GAME STATISTICS TABLE
CREATE TABLE game_statistics (
    stat_id INT PRIMARY KEY AUTO_INCREMENT,
    game_id INT NOT NULL,
    stat_date DATE NOT NULL,
    total_bets INT DEFAULT 0,
    total_wagered DECIMAL(15, 2) DEFAULT 0.00,
    total_payout DECIMAL(15, 2) DEFAULT 0.00,
    actual_rtp DECIMAL(5, 2),
    unique_players INT DEFAULT 0,
    FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE,
    INDEX idx_game_id (game_id),
    INDEX idx_date (stat_date),
    UNIQUE KEY unique_game_date (game_id, stat_date)
);

-- 20. PAYMENT METHODS TABLE
CREATE TABLE payment_methods (
    method_id INT PRIMARY KEY AUTO_INCREMENT,
    method_name VARCHAR(50) NOT NULL,
    method_type ENUM('deposit', 'withdrawal', 'both') DEFAULT 'both',
    status ENUM('active', 'inactive', 'maintenance') DEFAULT 'active',
    min_amount DECIMAL(10, 2),
    max_amount DECIMAL(10, 2),
    processing_time VARCHAR(50),
    fee_percentage DECIMAL(5, 2) DEFAULT 0.00,
    fee_fixed DECIMAL(10, 2) DEFAULT 0.00,
    instructions TEXT,
    icon_url VARCHAR(255),
    display_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (method_type),
    INDEX idx_status (status)
);

-- =============================================
-- INITIAL DATA INSERTS (Optional)
-- =============================================

-- Insert default admin
INSERT INTO admins (username, email, password_hash, full_name, role, permissions) 
VALUES ('admin', 'admin@gambling.com', '$2y$10$dummyhash', 'System Administrator', 'super_admin', '{"all": true}');

-- Insert some payment methods
INSERT INTO payment_methods (method_name, method_type, min_amount, max_amount, processing_time, instructions) VALUES
('UPI', 'both', 100.00, 100000.00, 'Instant', 'Enter your UPI ID'),
('Bank Transfer', 'both', 500.00, 500000.00, '1-3 business days', 'Enter your bank account details'),
('Credit Card', 'deposit', 100.00, 50000.00, 'Instant', 'Enter card details'),
('Cryptocurrency', 'both', 50.00, 1000000.00, '10-30 minutes', 'Send to provided wallet address');
