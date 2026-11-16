# Sample Size: n = 18 (out of N = 20 enrolled, 90% baseline coverage)
#Load Required Packages
library(tidyverse)
library(gtsummary)
library(gt)
install.packages("flextable")
library(flextable)
read_csv("Data/Grade_02_baseline_dadta_01.csv")
df_raw <-read_csv("Data/Grade_02_baseline_dadta_01.csv")
summary(df_raw)        
df_pre <- df_raw %>%
  rename_with(str_trim) %>%
  mutate(across(where(is.character), str_trim)) %>%
  filter(!is.na(Pre_Total_Score)) %>%
  mutate(
    Gender = factor(Gender, levels = c("Male", "Female")),
    Pre_Total_Score_Recalc = Pre_SecA_Score + Pre_SecB_Simple + Pre_SecB_Complex,
    Acc_Bare_Number  = (Pre_SecA_Score / 5) * 100,
    Acc_Simple_Word  = (Pre_SecB_Simple / 2) * 100,
    Acc_Complex_Word = (Pre_SecB_Complex / 3) * 100
  )
cat("Total Analytical Sample (n):", nrow(df_pre), "\n")

# TABLE 1: Baseline Summary Table by Gender (gtsummary)
table1_baseline <- df_pre %>%
  select(
    Gender, Baseline_Math_Grade, 
    Pre_SecA_Score, Pre_SecB_Simple, Pre_SecB_Complex, 
    Pre_Total_Score, Pre_Blank_Count, Pre_Add_Confusion
  ) %>%
  tbl_summary(
    by = Gender,
    type = list(
      c(Baseline_Math_Grade, Pre_SecA_Score, Pre_SecB_Simple, 
        Pre_SecB_Complex, Pre_Total_Score, Pre_Blank_Count, Pre_Add_Confusion) ~ "continuous"
    ),
    statistic = list(all_continuous() ~ "{mean} ({sd})"),
    digits = all_continuous() ~ 2,
    label = list(
      Baseline_Math_Grade ~ "Baseline Math Grade (0-100)",
      Pre_SecA_Score      ~ "Sec A: Bare Number Subtraction (Max 5)",
      Pre_SecB_Simple     ~ "Sec B: Simple Word Problems Q6-Q7 (Max 2)",
      Pre_SecB_Complex    ~ "Sec B: Complex Word Problems Q8-Q10 (Max 3)",
      Pre_Total_Score     ~ "Total Pre-Test Score (Max 10)",
      Pre_Blank_Count     ~ "Omission Errors / Blank Items (Count)",
      Pre_Add_Confusion   ~ "Operation Confusion / Added Instead of Subtracted"
    )
  ) %>%
  add_overall(last = FALSE) %>%
  add_p(test = list(all_continuous() ~ "wilcox.test")) %>%
  bold_labels() %>%
  modify_caption("**Table 1. Baseline Diagnostic Characteristics of Grade 2 Cohort (n = 18)**")

print(table1_baseline)
table1_baseline %>% 
  as_gt() %>% 
  gtsave("Figures/Tables/Table1_Baseline.docx")


#GRAPH 1: "The Semantic Cliff" (Mean Accuracy Across Problem Domains)

df_long <- df_pre %>%
  select(Student_ID, Gender, Acc_Bare_Number, Acc_Simple_Word, Acc_Complex_Word) %>%
  pivot_longer(
    cols = starts_with("Acc_"),
    names_to = "Problem_Type",
    values_to = "Accuracy_Pct"
  ) %>%
  mutate(
    Problem_Type = factor(
      Problem_Type,
      levels = c("Acc_Bare_Number", "Acc_Simple_Word", "Acc_Complex_Word"),
      labels = c(
        "Bare Numbers\n(Sec A: Q1-Q5)", 
        "Simple Word Problems\n(Sec B: Q6-Q7)", 
        "Complex Word Problems\n(Sec B: Q8-Q10)"
      )
    )
  )

plot_semantic_cliff <- ggplot(df_long, aes(x = Problem_Type, y = Accuracy_Pct, fill = Problem_Type)) +
  stat_summary(fun = mean, geom = "bar", width = 0.52, color = "black", alpha = 0.85) +
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.14, linewidth = 0.8) +
  geom_jitter(width = 0.10, height = 0, alpha = 0.65, size = 2.5, color = "#1a252f") +
  stat_summary(
    fun = mean, 
    geom = "text", 
    aes(label = sprintf("%.1f%%", after_stat(y))), 
    vjust = -2.2, fontface = "bold", size = 4.2
  ) +
  scale_fill_manual(values = c("#2b5c8f", "#e67e22", "#c0392b")) +
  scale_y_continuous(limits = c(0, 118), breaks = seq(0, 100, 20)) +
  labs(
    title = "Baseline Diagnostic: The Semantic-to-Symbolic Gap in Grade 2 Subtraction",
    subtitle = "Mean accuracy (%) drops by 46.7% on complex word problems (t = 6.11, p < 0.0001; n = 18)",
    x = "Subtraction Task Domain",
    y = "Mean Accuracy (%)",
    caption = "Note: Error bars represent +/- 1 SE. Dots represent individual students (Asadpur Govt. Primary School)."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", size = 13),
    plot.subtitle = element_text(color = "gray25", size = 10.5),
    axis.text.x = element_text(face = "bold", size = 10.5, color = "black"),
    panel.grid.minor = element_blank()
  )

print(plot_semantic_cliff)
ggsave("Figures/Graph/Graph1_Semantic_Cliff_Baseline.png", plot = plot_semantic_cliff, width = 8, height = 5.5, dpi = 300)















