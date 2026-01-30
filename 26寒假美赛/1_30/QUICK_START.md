# Quick Start Guide: DWTS Season 2 Heatmap Visualization

## 🚀 Quick Start

### Option 1: Run the Function Version
```matlab
% In MATLAB command window:
dwts_season2_heatmap_optimized()
```

### Option 2: Run the Script Version
```matlab
% In MATLAB command window:
dwts_season2_heatmap_script
```

---

## 📊 What You'll Get

A beautiful heatmap showing:
- **10 contestants** (rows) from DWTS Season 2
- **7 weeks** (columns) of competition
- **Color-coded probabilities** (red = high, yellow = low)
- **Actual elimination markers** (black dashed boxes)
- **Probability values** in each cell

---

## 🎨 Customization Examples

### Change Figure Size
```matlab
% Edit at the top of the script:
CONFIG.figure_size = [100, 100, 1200, 900];  % Width x Height
```

### Adjust Font Sizes
```matlab
CONFIG.text_font_size = 12;      % Cell labels
CONFIG.title_font_size = 16;     % Title
CONFIG.label_font_size = 14;     % Axis labels
```

### Change Color Resolution
```matlab
CONFIG.n_colors = 128;  % Smoother color gradient (default: 64)
```

### Modify Grid Appearance
```matlab
CONFIG.grid_alpha = 0.5;          % More visible (default: 0.3)
CONFIG.grid_line_width = 1.0;     # Thicker lines (default: 0.5)
```

---

## 💾 Save the Figure

Add these lines at the end of the script:

### Save as PNG (High Resolution)
```matlab
print('DWTS_Heatmap', '-dpng', '-r300');
```

### Save as MATLAB Figure
```matlab
saveas(gcf, 'DWTS_Heatmap.fig');
```

### Save as Vector Graphics (PDF)
```matlab
print('DWTS_Heatmap', '-dpdf', '-vector');
```

---

## 📁 File Descriptions

| File | Type | Purpose | Best For |
|------|------|---------|----------|
| `dwts_season2_heatmap_optimized.m` | Function | Modular, reusable | Production use |
| `dwts_season2_heatmap_script.m` | Script | Standalone, customizable | Quick testing |
| `README_HEATMAP_OPTIMIZATION.md` | Docs | Technical details | Understanding optimizations |
| `COMPARISON.md` | Docs | Before/after comparison | Learning improvements |
| `QUICK_START.md` | Docs | This guide | Getting started |

---

## 🔧 System Requirements

- **MATLAB Version**: R2016b or later (recommended)
- **Minimum**: R2014a
- **Toolboxes**: None required (base MATLAB only)
- **OS**: Windows, macOS, Linux

---

## 📖 Understanding the Data

### Probability Matrix Structure
```
prob_matrix(i, j) = probability that contestant i is eliminated in week j

- Value > 0: Active probability
- Value = 0: Already eliminated or safe
```

### Example
```matlab
prob_matrix(1, 1) = 0.151  % Kenny Mayne: 15.1% chance in Week 1
prob_matrix(1, 2) = 0.000  % Kenny Mayne: Already eliminated
```

---

## ❓ Common Issues & Solutions

### Issue: "Undefined function or variable"
**Solution**: Make sure you're in the correct directory
```matlab
cd '/path/to/Mathematical-Modeling-Contest/26寒假美赛/1_30'
```

### Issue: Figure is too small
**Solution**: Adjust figure size
```matlab
CONFIG.figure_size = [100, 100, 1200, 900];
```

### Issue: Text is hard to read
**Solution**: Increase font size
```matlab
CONFIG.text_font_size = 12;
```

### Issue: Can't see grid lines
**Solution**: Increase grid visibility
```matlab
CONFIG.grid_alpha = 0.5;
CONFIG.grid_line_width = 1.0;
```

---

## 🎯 Key Features

✅ **Fast**: 3-5x faster colormap generation  
✅ **Clean**: Modular, well-documented code  
✅ **Flexible**: Easy to customize all parameters  
✅ **Beautiful**: Professional-quality visualization  
✅ **Reusable**: Functions can be used in other projects  

---

## 📈 Advanced Usage

### Batch Processing Multiple Seasons
```matlab
seasons = [1, 2, 3, 4, 5];
for s = seasons
    % Load season data
    data = load_season_data(s);
    % Create heatmap
    create_heatmap(data, config);
    % Save
    print(sprintf('Season_%d_Heatmap', s), '-dpng', '-r300');
end
```

### Custom Color Schemes
```matlab
% Blue-to-red gradient
t = linspace(0, 1, CONFIG.n_colors)';
custom_colormap = [t, zeros(CONFIG.n_colors, 1), 1-t];
colormap(custom_colormap);
```

### Export Data to CSV
```matlab
% Export probability matrix
writematrix(prob_matrix, 'elimination_probabilities.csv');

% Export with headers
T = array2table(prob_matrix, ...
    'RowNames', contestants, ...
    'VariableNames', weeks);
writetable(T, 'elimination_probabilities.csv', 'WriteRowNames', true);
```

---

## 📞 Support

For questions or issues:
1. Check the [README_HEATMAP_OPTIMIZATION.md](README_HEATMAP_OPTIMIZATION.md) for technical details
2. Review the [COMPARISON.md](COMPARISON.md) for optimization explanations
3. Examine the code comments for inline documentation

---

## 📝 License

Part of the Mathematical Modeling Contest repository.

---

## 🎓 Learning Resources

### Understanding Heatmaps
- [MATLAB Heatmap Documentation](https://www.mathworks.com/help/matlab/ref/heatmap.html)
- [Data Visualization Best Practices](https://www.mathworks.com/help/matlab/creating_plots/types-of-matlab-plots.html)

### MATLAB Optimization
- [Vectorization in MATLAB](https://www.mathworks.com/help/matlab/matlab_prog/vectorization.html)
- [Code Performance](https://www.mathworks.com/help/matlab/performance-and-memory.html)

---

**Version**: 1.0  
**Last Updated**: January 30, 2026  
**Maintained by**: Mathematical Modeling Contest Team
