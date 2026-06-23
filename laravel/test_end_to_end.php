<?php

/**
 * END-TO-END TEST SCRIPT: FOTO BUKTI INVESTIGATION
 * 
 * This script will:
 * 1. Check storage directory structure
 * 2. List recent files in bukti folder
 * 3. Verify symlink accessibility
 * 4. Parse recent Laravel logs for foto upload entries
 * 5. Provide diagnostic summary
 */

require __DIR__.'/vendor/autoload.php';

$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "═══════════════════════════════════════════════════════════════\n";
echo "  END-TO-END FOTO BUKTI INVESTIGATION\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

// 1. Check storage directories
echo "1️⃣ CHECKING STORAGE DIRECTORIES\n";
echo "─────────────────────────────────────────────────────────────\n";

$storagePublicPath = storage_path('app/public/bukti');
$publicSymlinkPath = public_path('storage/bukti');

echo "Storage path: {$storagePublicPath}\n";
echo "  ├─ Exists: " . (is_dir($storagePublicPath) ? "✅ YES" : "❌ NO") . "\n";
echo "  └─ Writable: " . (is_writable(dirname($storagePublicPath)) ? "✅ YES" : "❌ NO") . "\n\n";

echo "Public symlink: {$publicSymlinkPath}\n";
echo "  ├─ Exists: " . (file_exists($publicSymlinkPath) ? "✅ YES" : "❌ NO") . "\n";
echo "  └─ Is link: " . (is_link(public_path('storage')) ? "✅ YES (symlink)" : "⚠️ NO (real dir/missing)") . "\n\n";

// 2. List recent files
echo "\n2️⃣ RECENT FILES IN BUKTI FOLDER\n";
echo "─────────────────────────────────────────────────────────────\n";

if (is_dir($storagePublicPath)) {
    $files = glob($storagePublicPath . '/*.{jpg,jpeg,png,JPG,JPEG,PNG}', GLOB_BRACE);
    
    if (empty($files)) {
        echo "⚠️ No image files found in bukti folder\n\n";
    } else {
        // Sort by modification time (newest first)
        usort($files, function($a, $b) {
            return filemtime($b) - filemtime($a);
        });
        
        $recentFiles = array_slice($files, 0, 5);
        
        echo "Showing " . count($recentFiles) . " most recent file(s):\n\n";
        
        foreach ($recentFiles as $index => $file) {
            $fileName = basename($file);
            $fileSize = filesize($file);
            $fileTime = date('Y-m-d H:i:s', filemtime($file));
            $fileAge = time() - filemtime($file);
            $ageStr = $fileAge < 3600 ? round($fileAge / 60) . " minutes ago" : round($fileAge / 3600, 1) . " hours ago";
            
            echo ($index + 1) . ". {$fileName}\n";
            echo "   ├─ Size: " . number_format($fileSize) . " bytes\n";
            echo "   ├─ Modified: {$fileTime} ({$ageStr})\n";
            
            // Check if accessible via symlink
            $symlinkFile = public_path("storage/bukti/{$fileName}");
            $accessible = file_exists($symlinkFile);
            echo "   └─ Accessible via symlink: " . ($accessible ? "✅ YES" : "❌ NO") . "\n\n";
        }
    }
} else {
    echo "❌ Storage bukti folder does not exist!\n\n";
}

// 3. Check Laravel logs for recent foto upload entries
echo "\n3️⃣ RECENT FOTO UPLOAD LOG ENTRIES\n";
echo "─────────────────────────────────────────────────────────────\n";

$logFile = storage_path('logs/laravel.log');

if (file_exists($logFile)) {
    $logContent = file_get_contents($logFile);
    
    // Find all "Save Foto Bukti" entries
    preg_match_all('/\[.*?\] local\.INFO: Save Foto Bukti (.*?)(?=\[\d{4}|$)/s', $logContent, $matches, PREG_SET_ORDER);
    
    if (empty($matches)) {
        echo "⚠️ No 'Save Foto Bukti' log entries found\n";
        echo "   This means either:\n";
        echo "   - No foto upload has been attempted since debug logging was added\n";
        echo "   - OR the app hasn't processed any transaction with foto_bukti\n\n";
    } else {
        $recentMatches = array_slice($matches, -3); // Last 3 entries
        
        echo "Found " . count($matches) . " upload log entries. Showing last " . count($recentMatches) . ":\n\n";
        
        foreach ($recentMatches as $index => $match) {
            echo "Entry " . ($index + 1) . ":\n";
            echo substr($match[0], 0, 800) . "\n"; // Limit output
            echo "─────────────────────────────────────────────────────────────\n";
        }
    }
    
    // Find all "Transaksi Created" entries
    preg_match_all('/\[.*?\] local\.INFO: Transaksi Created (.*?)(?=\[\d{4}|$)/s', $logContent, $transMatches, PREG_SET_ORDER);
    
    if (!empty($transMatches)) {
        echo "\n\n4️⃣ RECENT TRANSAKSI CREATION LOG ENTRIES\n";
        echo "─────────────────────────────────────────────────────────────\n";
        
        $recentTransMatches = array_slice($transMatches, -3);
        echo "Found " . count($transMatches) . " creation log entries. Showing last " . count($recentTransMatches) . ":\n\n";
        
        foreach ($recentTransMatches as $index => $match) {
            echo "Entry " . ($index + 1) . ":\n";
            
            // Parse JSON data
            if (preg_match('/\{[^}]*"foto_bukti":"([^"]*)"[^}]*\}/', $match[0], $jsonMatch)) {
                $fullJson = $jsonMatch[0];
                $data = json_decode($fullJson, true);
                
                if ($data) {
                    echo "   ├─ ID: " . ($data['id'] ?? 'N/A') . "\n";
                    echo "   ├─ foto_bukti: " . ($data['foto_bukti'] ?? 'NULL') . "\n";
                    echo "   ├─ user_id: " . ($data['user_id'] ?? 'N/A') . "\n";
                    echo "   ├─ user_name: " . ($data['user_name'] ?? 'N/A') . "\n";
                    echo "   └─ created_by_name: " . ($data['created_by_name_accessor'] ?? 'N/A') . "\n\n";
                } else {
                    echo substr($match[0], 0, 400) . "\n\n";
                }
            } else {
                echo substr($match[0], 0, 400) . "\n\n";
            }
            
            echo "─────────────────────────────────────────────────────────────\n";
        }
    }
    
} else {
    echo "❌ Log file not found at: {$logFile}\n\n";
}

// 5. Database check - recent transactions
echo "\n\n5️⃣ RECENT TRANSACTIONS IN DATABASE\n";
echo "─────────────────────────────────────────────────────────────\n";

try {
    $recentTransaksis = \App\Models\Transaksi::with('user')
        ->orderByDesc('id')
        ->limit(5)
        ->get(['id', 'user_id', 'foto_bukti', 'tanggal', 'created_at']);
    
    echo "Showing " . $recentTransaksis->count() . " most recent transaction(s):\n\n";
    
    foreach ($recentTransaksis as $index => $transaksi) {
        echo ($index + 1) . ". ID: {$transaksi->id}\n";
        echo "   ├─ Created: " . $transaksi->created_at->format('Y-m-d H:i:s') . "\n";
        echo "   ├─ user_id: " . ($transaksi->user_id ?? 'NULL') . "\n";
        echo "   ├─ user->name: " . ($transaksi->user?->name ?? 'NULL/Not Loaded') . "\n";
        echo "   ├─ created_by_name accessor: " . $transaksi->created_by_name . "\n";
        echo "   └─ foto_bukti: " . ($transaksi->foto_bukti ?? 'NULL') . "\n";
        
        // If foto_bukti exists, check if file actually exists
        if ($transaksi->foto_bukti) {
            $filePath = storage_path("app/public/{$transaksi->foto_bukti}");
            $exists = file_exists($filePath);
            echo "      └─ File exists on disk: " . ($exists ? "✅ YES" : "❌ NO (MISSING!)") . "\n";
        }
        
        echo "\n";
    }
    
} catch (\Exception $e) {
    echo "❌ Database error: " . $e->getMessage() . "\n\n";
}

// 6. Summary & Recommendations
echo "\n═══════════════════════════════════════════════════════════════\n";
echo "  📊 DIAGNOSTIC SUMMARY\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

echo "✅ Test script completed.\n\n";
echo "NEXT STEPS FOR USER:\n";
echo "1. Review the output above\n";
echo "2. Create a NEW transaction via Flutter app with foto upload\n";
echo "3. Run this script again IMMEDIATELY after transaction creation\n";
echo "4. Compare the 'Recent Files' and 'Recent Transactions' sections\n";
echo "5. Check if the new foto file appears in both storage AND database\n";
echo "6. Share the complete output with the developer\n\n";

echo "KEY QUESTIONS TO ANSWER:\n";
echo "- Does the foto file physically exist in storage/app/public/bukti?\n";
echo "- Is the foto_bukti field populated in database?\n";
echo "- Is the file accessible via public/storage symlink?\n";
echo "- Does created_by_name show the correct username or 'Tidak diketahui'?\n";
echo "- Are there any error messages in the log entries?\n\n";

echo "═══════════════════════════════════════════════════════════════\n";
