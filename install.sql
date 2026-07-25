-- phpMyAdmin SQL Dump
-- version 4.0.4.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 30, 2013 at 09:45 PM
-- Server version: 5.6.10
-- PHP Version: 5.3.15

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

-- --------------------------------------------------------

--
-- Table structure for table `antispam`
--

CREATE TABLE IF NOT EXISTS `antispam` (
  `board` varchar(58) CHARACTER SET utf8 NOT NULL,
  `thread` int(11) DEFAULT NULL,
  `hash` char(40) COLLATE ascii_bin NOT NULL,
  `created` int(11) NOT NULL,
  `expires` int(11) DEFAULT NULL,
  `passed` smallint(6) NOT NULL,
  PRIMARY KEY (`hash`),
  KEY `board` (`board`,`thread`),
  KEY `expires` (`expires`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- --------------------------------------------------------

--
-- Table structure for table `bans`
--

CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ipstart` varbinary(16) NOT NULL,
  `ipend` varbinary(16) DEFAULT NULL,
  `created` int(10) unsigned NOT NULL,
  `expires` int(10) unsigned DEFAULT NULL,
  `board` varchar(58) DEFAULT NULL,
  `creator` int(10) NOT NULL,
  `reason` text,
  `seen` tinyint(1) NOT NULL,
  `post` blob,
  PRIMARY KEY (`id`),
  KEY `expires` (`expires`),
  KEY `ipstart` (`ipstart`,`ipend`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `boards`
--

CREATE TABLE IF NOT EXISTS `boards` (
  `uri` varchar(58) CHARACTER SET utf8 NOT NULL,
  `title` tinytext NOT NULL,
  `subtitle` tinytext,
  -- `indexed` boolean default true,
  PRIMARY KEY (`uri`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `boards`
--

INSERT INTO `boards` VALUES
('b', 'Random', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cites`
--

CREATE TABLE IF NOT EXISTS `cites` (
  `board` varchar(58) NOT NULL,
  `post` int(11) NOT NULL,
  `target_board` varchar(58) NOT NULL,
  `target` int(11) NOT NULL,
  KEY `target` (`target_board`,`target`),
  KEY `post` (`board`,`post`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `ip_notes`
--

CREATE TABLE IF NOT EXISTS `ip_notes` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(39) CHARACTER SET ascii NOT NULL,
  `mod` int(11) DEFAULT NULL,
  `time` int(11) NOT NULL,
  `body` text NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `ip_lookup` (`ip`, `time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `modlogs`
--

CREATE TABLE IF NOT EXISTS `modlogs` (
  `mod` int(11) NOT NULL,
  `ip` varchar(39) CHARACTER SET ascii NOT NULL,
  `board` varchar(58) CHARACTER SET utf8 DEFAULT NULL,
  `time` int(11) NOT NULL,
  `text` text NOT NULL,
  KEY `time` (`time`),
  KEY `mod`(`mod`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `mods`
--

CREATE TABLE IF NOT EXISTS `mods` (
  `id` smallint(6) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(30) NOT NULL,
  `password` varchar(256) CHARACTER SET ascii NOT NULL COMMENT 'SHA256',
  `version` varchar(64) CHARACTER SET ascii NOT NULL,
  `type` smallint(2) NOT NULL,
  `boards` text CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`,`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

--
-- Dumping data for table `mods`
--

INSERT INTO `mods` VALUES
(1, 'admin', 'cedad442efeef7112fed0f50b011b2b9bf83f6898082f995f69dd7865ca19fb7', '4a44c6c55df862ae901b413feecb0d49', 30, '*');

-- --------------------------------------------------------

--
-- Table structure for table `mutes`
--

CREATE TABLE IF NOT EXISTS `mutes` (
  `ip` varchar(39) NOT NULL,
  `time` int(11) NOT NULL,
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;

-- --------------------------------------------------------

--
-- Table structure for table `news`
--

CREATE TABLE IF NOT EXISTS `news` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `time` int(11) NOT NULL,
  `subject` text NOT NULL,
  `body` text NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `noticeboard`
--

CREATE TABLE IF NOT EXISTS `noticeboard` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `mod` int(11) NOT NULL,
  `time` int(11) NOT NULL,
  `subject` text NOT NULL,
  `body` text NOT NULL,
  UNIQUE KEY `id` (`id`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `pms`
--

CREATE TABLE IF NOT EXISTS `pms` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `sender` int(11) NOT NULL,
  `to` int(11) NOT NULL,
  `message` text NOT NULL,
  `time` int(11) NOT NULL,
  `unread` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `to` (`to`, `unread`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE IF NOT EXISTS `reports` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `time` int(11) NOT NULL,
  `ip` varchar(39) CHARACTER SET ascii NOT NULL,
  `board` varchar(58) CHARACTER SET utf8 DEFAULT NULL,
  `post` int(11) NOT NULL,
  `reason` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `robot`
--

CREATE TABLE IF NOT EXISTS `robot` (
  `hash` varchar(40) COLLATE ascii_bin NOT NULL COMMENT 'SHA1',
  PRIMARY KEY (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin;

-- --------------------------------------------------------

--
-- Table structure for table `search_queries`
--

CREATE TABLE IF NOT EXISTS `search_queries` (
  `ip` varchar(39) NOT NULL,
  `time` int(11) NOT NULL,
  `query` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `theme_settings`
--

CREATE TABLE IF NOT EXISTS `theme_settings` (
  `theme` varchar(40) NOT NULL,
  `name` varchar(40) DEFAULT NULL,
  `value` text,
  KEY `theme` (`theme`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `flood`
--

CREATE TABLE IF NOT EXISTS `flood` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(39) NOT NULL,
  `board` varchar(58) CHARACTER SET utf8 NOT NULL,
  `time` int(11) NOT NULL,
  `posthash` char(32) NOT NULL,
  `filehash` char(32) DEFAULT NULL,
  `isreply` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ip` (`ip`),
  KEY `posthash` (`posthash`),
  KEY `filehash` (`filehash`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii COLLATE=ascii_bin AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `ban_appeals`
--

CREATE TABLE IF NOT EXISTS `ban_appeals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ban_id` int(10) unsigned NOT NULL,
  `time` int(10) unsigned NOT NULL,
  `message` text NOT NULL,
  `denied` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ban_id` (`ban_id`),
  CONSTRAINT `fk_ban_id` FOREIGN KEY (`ban_id`) REFERENCES `bans`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- Table structure for table `pages`
--

CREATE TABLE IF NOT EXISTS `pages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `board` varchar(58) CHARACTER SET utf8 DEFAULT NULL,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `content` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `u_pages` (`name`,`board`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `nntp_references`
--

CREATE TABLE IF NOT EXISTS `nntp_references` (
  `board` varchar(30) NOT NULL,
  `id` int(11) unsigned NOT NULL,
  `message_id` varchar(255) CHARACTER SET ascii NOT NULL,
  `message_id_digest` varchar(40) CHARACTER SET ascii NOT NULL,
  `own` tinyint(1) NOT NULL,
  `headers` text,
  PRIMARY KEY (`message_id_digest`),
  UNIQUE KEY `message_id` (`message_id`),
  UNIQUE KEY `u_board_id` (`board`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `nntp_peers`
--
-- NNTPChan peers to pull articles from / push to. Managed from the mod panel (?/nntpchan).
--

CREATE TABLE IF NOT EXISTS `nntp_peers` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL DEFAULT '',
  `host` VARCHAR(255) NOT NULL,
  `port` INT(11) NOT NULL DEFAULT 119,
  `enabled` TINYINT(1) NOT NULL DEFAULT 1,
  `last_sync` INT(11) NOT NULL DEFAULT 0,
  `created` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `nntp_groupmap`
--
-- Maps an NNTPChan newsgroup (overchan.*) to a local board. Managed from ?/nntpchan.
--

CREATE TABLE IF NOT EXISTS `nntp_groupmap` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `newsgroup` VARCHAR(255) NOT NULL,
  `board` VARCHAR(58) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `newsgroup` (`newsgroup`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `nsfw_settings`
--
-- Per-board NSFW-filter policy (Yahoo open_nsfw scoring, see inc/nsfw.php). The row with an
-- empty `board` is the site-wide default applied to every board that has no row of its own;
-- a board-specific row overrides it. `action` is 'reject' or 'spoiler'.
--
CREATE TABLE IF NOT EXISTS `nsfw_settings` (
  `board` VARCHAR(58) NOT NULL DEFAULT '',
  `enabled` TINYINT(1) NOT NULL DEFAULT 0,
  `threshold` FLOAT NOT NULL DEFAULT 0.8,
  `action` VARCHAR(16) NOT NULL DEFAULT 'reject',
  `updated` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`board`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `nntp_ban_tombstone`
--
-- Records image-ban fingerprints that were federated-unbanned, so a later (out-of-order)
-- ban control message for the same fingerprint is ignored. See inc/nntpchan/sync.php.
--

CREATE TABLE IF NOT EXISTS `nntp_ban_tombstone` (
  `hash` VARCHAR(64) NOT NULL,
  `created` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`hash`)
) ENGINE=InnoDB DEFAULT CHARSET=ascii;

-- --------------------------------------------------------

--
-- Table structure for table `nntp_settings`
--
-- Runtime NNTPChan toggles set from the mod panel (?/nntpchan), e.g. the outbound content
-- federation tickbox (`outbound_enabled`).
--

CREATE TABLE IF NOT EXISTS `nntp_settings` (
  `name` VARCHAR(64) NOT NULL,
  `value` TEXT,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `deleted_thread`
--
-- Deleted-thread tombstones: a moderator-deleted thread's root Message-ID is recorded here
-- so the NNTPChan sync refuses to re-import it for a retention window (see
-- $config['nntpchan']['tombstone_days']). Purely local state; never sent over NNTP.
--

CREATE TABLE IF NOT EXISTS `deleted_thread` (
  `root_msgid_digest` VARCHAR(40) CHARACTER SET ascii NOT NULL,
  `root_message_id` VARCHAR(255) CHARACTER SET ascii NOT NULL,
  `board` VARCHAR(58) DEFAULT NULL,
  `deleted_at` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`root_msgid_digest`),
  KEY `deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `captchas`
--

CREATE TABLE IF NOT EXISTS `captchas` (
  `cookie` VARCHAR(50),
  `extra` VARCHAR(200),
  `text` VARCHAR(255),
  `created_at` INT(11),
  PRIMARY KEY (`cookie`,`extra`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `anime_captcha`
--
-- Pool of challenges for the native "anime" captcha. Each row is one image and
-- the character/answer it depicts; the answer choices shown to a user are drawn
-- from the `answer` values across the pool. Managed from the mod panel (?/captcha).
--

CREATE TABLE IF NOT EXISTS `anime_captcha` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(200) NOT NULL DEFAULT '',
  `image_url` TEXT NOT NULL,
  `question` VARCHAR(255) NOT NULL DEFAULT '',
  `answer` VARCHAR(255) NOT NULL,
  `created_at` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `category` (`category`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `captcha_categories`
--
-- A grid-captcha category and the prompt shown above its 4x4 grid (e.g.
-- name="cats", prompt="Select all cats"). Imported from a leomotors category
-- title, or added from the mod panel (?/captcha).
--

CREATE TABLE IF NOT EXISTS `captcha_categories` (
  `name` VARCHAR(64) NOT NULL,
  `prompt` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `captcha_grid_images`
--
-- The image pool for the reCAPTCHA-style grid captcha. Each image belongs to a
-- category and is flagged is_target=1 when it matches that category's prompt
-- (i.e. the user should select it). A challenge draws a mix of target and
-- non-target images into a 4x4 grid; the correct selection is kept server-side.
--

CREATE TABLE IF NOT EXISTS `captcha_grid_images` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `category` VARCHAR(64) NOT NULL,
  `image_url` TEXT NOT NULL,
  `is_target` TINYINT(1) NOT NULL DEFAULT 0,
  `label` VARCHAR(255) NOT NULL DEFAULT '',
  `created_at` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `cat_target` (`category`, `is_target`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `boardlinks`
--
-- Admin-managed entries for the navigation "boardlinks" bar (see createBoardlist()).
-- A row with an empty `url` is a link to the board named in `title`; a row with a
-- `url` is a custom link labelled `title`. A non-empty `group_name` places the entry
-- inside a [bracketed] group. Managed from the mod panel (?/boardlinks).
--

CREATE TABLE IF NOT EXISTS `boardlinks` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `group_name` VARCHAR(255) NOT NULL DEFAULT '',
  `title` VARCHAR(255) NOT NULL,
  `url` VARCHAR(255) NOT NULL DEFAULT '',
  `position` INT(11) NOT NULL DEFAULT 0,
  `created_at` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `position` (`position`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `image_hashes`
--
-- Blacklist of image hashes. Perceptual hashes (phash/dhash/ahash) are matched by Hamming
-- distance so near-duplicate images are caught; exact hashes (md5/sha1/sha256) match only
-- identical files. Each row records the algorithm so hashes from any tool can be imported.
-- Managed from the mod panel (?/image-hashes).
--

CREATE TABLE IF NOT EXISTS `image_hashes` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `algo` VARCHAR(16) NOT NULL DEFAULT 'phash',
  `hash` VARCHAR(64) NOT NULL,
  `bits` SMALLINT(6) NOT NULL DEFAULT 0,
  `note` VARCHAR(255) NOT NULL DEFAULT '',
  `created` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `algo_hash` (`algo`,`hash`),
  KEY `algo` (`algo`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `emergency`
--
-- One row per board that is currently in emergency mode (frozen). The special board '*'
-- means every board is frozen (set by an admin). While a board is frozen, non-staff posts
-- are held in `post_queue` for approval instead of being published.
--

CREATE TABLE IF NOT EXISTS `emergency` (
  `board` VARCHAR(58) NOT NULL,
  `mod_id` INT(11) NOT NULL DEFAULT 0,
  `created` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`board`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `post_queue`
--
-- Posts held for moderator approval while a board is in emergency mode. `post_data` is the
-- fully-prepared post (PHP serialize) that is replayed through the normal insert on approval;
-- the other columns are for displaying the queue.
--

CREATE TABLE IF NOT EXISTS `post_queue` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `board` VARCHAR(58) NOT NULL,
  `thread` INT(11) DEFAULT NULL,
  `is_op` TINYINT(1) NOT NULL DEFAULT 0,
  `ip` VARCHAR(45) NOT NULL DEFAULT '',
  `time` INT(11) NOT NULL DEFAULT 0,
  `subject` VARCHAR(100) NOT NULL DEFAULT '',
  `name` VARCHAR(100) NOT NULL DEFAULT '',
  `body` TEXT,
  `num_files` INT(11) NOT NULL DEFAULT 0,
  `post_data` MEDIUMBLOB NOT NULL,
  `created` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `board` (`board`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4;


/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

