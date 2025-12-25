#include"common.hpp"
#include <cmath>
#include <fstream>
#include <sstream>
#include <chrono> // 添加计时功能

using namespace std;
using namespace chrono;  // 添加计时功能



int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    auto total_start = high_resolution_clock::now();  // 总计时开始

    // 文件路径
    string pointsFile = "points.txt";
    string edgesFile = "edges.txt";
    string sourcesFile = "sources.txt";
    string outputDir = "./output/";
    string pointsResultFile = outputDir + "result_points.txt";
    string edgesResultFile = outputDir + "result_edges.txt";

    // 读取节点数据
    auto start = high_resolution_clock::now();
    vector<Point> pts;
    unordered_map<int, int> id2idx;

    if (!readPointsFile(pointsFile, pts, id2idx)) {
        cerr << "读取节点文件失败！" << endl;
        return 1;
    }

    int n = pts.size();
    auto end = high_resolution_clock::now();
    cout << "成功读取 " << n << " 个节点 ("
        << duration_cast<milliseconds>(end - start).count() << "ms)" << endl;

    // 读取边数据
    start = high_resolution_clock::now();
    vector<Edge> edges;
    vector<vector<pair<int, int>>> adj(n);

    if (!readEdgesFile(edgesFile, edges, adj, id2idx, pts)) {
        cerr << "读取边文件失败！" << endl;
        return 1;
    }

    int m = edges.size();
    end = high_resolution_clock::now();
    cout << "成功读取 " << m << " 条边 ("
        << duration_cast<milliseconds>(end - start).count() << "ms)" << endl;

    // 读取水源数据
    start = high_resolution_clock::now();
    vector<pair<int, double>> sources;
    if (!readSourcesFile(sourcesFile, sources, id2idx)) {
        cerr << "读取水源文件失败！" << endl;
        return 1;
    }

    end = high_resolution_clock::now();
    cout << "成功读取 " << sources.size() << " 个水源 ("
        << duration_cast<milliseconds>(end - start).count() << "ms)" << endl;

    // 记录节点的首次到达时间与累积到达流量
    vector<double> node_arrival(n, INF);
    vector<double> node_totalQ(n, 0.0);

    // 优先队列（最小堆）用于事件驱动模拟
    priority_queue<Event> pq;

    // 初始化源事件：每个水源在时间0开始注入
    for (auto& s : sources) {
        Event ev;
        ev.t = 0.0;
        ev.node = s.first;
        ev.from = -1;
        ev.from_edge = -1;
        ev.Q = s.second;
        pq.push(ev);
    }

    // 主循环：处理事件
    start = high_resolution_clock::now();
    long long event_count = 0;
    long long max_queue_size = 0;

    while (!pq.empty()) {
        event_count++;
        max_queue_size = max(max_queue_size, (long long)pq.size());

        Event ev = pq.top();
        pq.pop();
        int u = ev.node;
        double t = ev.t;
        int from = ev.from;
        int from_edge = ev.from_edge;
        double Q = ev.Q;

        if (Q <= 0) continue;

        // 更新节点最早到达时间（如果是更早的到达）
        if (t + EPS < node_arrival[u])
            node_arrival[u] = t;

        // 累加到节点的总流量
        node_totalQ[u] += Q;

        // 找出可以向外传播的邻边
        // 使用局部变量避免多次访问adj[u]
        const auto& neighbors = adj[u];
        vector<pair<int, int>> outs;
        outs.reserve(neighbors.size());

        for (const auto& p : neighbors) {
            int v = p.first;
            int eid = p.second;

            // 检查边的另一端是否已有水流到达
            const Edge& e = edges[eid];
            bool neighborReached = (e.u == u) ? e.used_v : e.used_u;

            // 选择尚未使用的边，且排除来向
            if (!neighborReached && (from == -1 || v != from)) {
                outs.push_back(p);
            }
        }

        // 如果没有可传播的出口（死端）
        if (outs.empty()) {
            if (from_edge != -1) {
                Edge& e = edges[from_edge];
                double needVol = WIDTH * (H_TOP - H0) * e.len;
                if (Q > EPS) {
                    double fill_time = t + needVol / Q;
                    if (e.t_full < 0.0)
                        e.t_full = fill_time;
                }
            }
            continue;
        }

        // 有可传播的出口：将当前节点的累计流量平均分配到各出口
        int k = (int)outs.size();
        double Q_each = node_totalQ[u] / k;
        node_totalQ[u] = 0.0;

        // 预计算速度系数
        double speed_coeff = Q_each * INV_AREA;

        // 处理每个出口
        for (const auto& p : outs) {
            int v = p.first;
            int eid = p.second;
            Edge& e = edges[eid];

            if (speed_coeff <= EPS) continue;

            // 使用预计算的倒数加速计算
            double travel_time = e.inv_len / speed_coeff;
            double arrive_time = t + travel_time;

            if (e.u == u) {
                if (arrive_time + EPS < e.t_v)
                    e.t_v = arrive_time;
                e.used_u = true;
            }
            else {
                if (arrive_time + EPS < e.t_u)
                    e.t_u = arrive_time;
                e.used_v = true;
            }

            Event nev;
            nev.t = arrive_time;
            nev.node = v;
            nev.from = u;
            nev.from_edge = eid;
            nev.Q = Q_each;
            pq.push(nev);
        }
    }

    end = high_resolution_clock::now();
    auto simulation_time = duration_cast<milliseconds>(end - start).count();

    // 保存结果到文件
    start = high_resolution_clock::now();

 

    savePointsResult(pointsResultFile, pts, node_arrival);
    saveEdgesResult(edgesResultFile, edges);

    end = high_resolution_clock::now();
    auto save_time = duration_cast<milliseconds>(end - start).count();

    // 控制台输出汇总信息
    auto total_end = high_resolution_clock::now();
    auto total_time = duration_cast<milliseconds>(total_end - total_start).count();

    cout << "\n======= 模拟完成 =======" << endl;
    cout << "总处理时间: " << total_time << "ms" << endl;
    cout << "模拟计算时间: " << simulation_time << "ms" << endl;
    cout << "文件保存时间: " << save_time << "ms" << endl;
    cout << "处理事件总数: " << event_count << endl;
    cout << "最大队列大小: " << max_queue_size << endl;

    // 计算已到达节点数
    int reached_nodes = 0;
    for (double t : node_arrival) {
        if (t < INF / 2) reached_nodes++;
    }
    cout << "已到达节点数: " << reached_nodes << "/" << n << endl;

    int filled_edges = 0;
    for (const auto& e : edges) {
        if (e.t_full > 0) filled_edges++;
    }
    cout << "已充满边数: " << filled_edges << "/" << m << endl;

    return 0;
}