#pragma once
#include <iostream>
#include <vector>
#include <unordered_map>
#include <queue>
#include <string>
#include <algorithm>
#include <iomanip>


// 常量定义
const double WIDTH = 4.0;    // 巷道宽度 (m)
const double H_TOP = 3.0;    // 巷道总高度 (m)
const double H0 = 0.1;       // 初始水位 (m)
const double AREA = WIDTH * H0; // 初始过水断面面积 (m^2)
const double EPS = 1e-9;     // 浮点数比较容差
const double INF = 1e100;    // 表示无穷大的大数
const double INV_AREA = 1.0 / AREA;  // 预计算倒数，减少除法运算



// 节点结构体
struct Point {
    int id;        // 节点ID（去掉P前缀后的数字）
    double x, y, z; // 三维坐标
};

// 边结构体
struct Edge {
    int id;         // 边ID（去掉H前缀后的数字）
    int u, v;       // 两个端点的索引
    double len;     // 边的长度
    double inv_len; // 长度的倒数，用于加速计算
    // 两端点的首次到达时间（未到达则为INF）
    double t_u = INF;
    double t_v = INF;
    // 该边被完全充满的时间（从初始到顶部H_TOP），-1表示未充满
    double t_full = -1.0;
    bool used_u = false; // 标记u端是否已有水流通过
    bool used_v = false; // 标记v端是否已有水流通过
};

// 事件结构体
struct Event {
    double t;    // 事件发生时间（分钟）
    int node;    // 到达的节点索引
    int from;    // 来自哪个节点索引（-1表示源）
    int from_edge = -1;  // 来自哪条边索引（-1表示源）
    double Q;    // 该事件带来的流量（m^3/min）
    // 优先队列比较运算符，时间小的先出队
    bool operator<(Event const& o) const {
        return t > o.t;  // 注意：优先队列默认大顶堆，这里反向比较实现小顶堆
    }
};



// 辅助函数：从字符串中提取ID数字（如从"P0000"提取0）
int extractId(const string& str) {
    if (str.empty()) return -1;

    // 跳过开头的非数字字符
    const char* p = str.c_str();
    while (*p && !isdigit(*p)) p++;

    if (*p == '\0') return -1;

    // 手动解析数字，避免创建临时字符串
    int result = 0;
    while (*p && isdigit(*p)) {
        result = result * 10 + (*p - '0');
        p++;
    }
    return result;
}

// 辅助函数：批量解析字符串为浮点数
inline void parseFloats(const string& line, double& x, double& y, double& z) {
    const char* p = line.c_str();

    // 跳过ID部分
    while (*p && !isdigit(*p)) {
        while (*p && !isspace(*p)) p++;  // 跳过ID
        while (*p && isspace(*p)) p++;   // 跳过空白
        break;
    }

    // 解析x
    x = atof(p);
    while (*p && !isspace(*p)) p++;  // 跳过x
    while (*p && isspace(*p)) p++;   // 跳过空白

    // 解析y
    y = atof(p);
    while (*p && !isspace(*p)) p++;  // 跳过y
    while (*p && isspace(*p)) p++;   // 跳过空白

    // 解析z
    z = atof(p);
}

// 辅助函数：批量解析边数据
inline void parseEdge(const string& line, string& edgeIdStr, string& uStr, string& vStr) {
    istringstream iss(line);
    iss >> edgeIdStr >> uStr >> vStr;
}

// 辅助函数：读取points.txt文件
bool readPointsFile(const string& filename, vector<Point>& points, unordered_map<int, int>& id2idx) {
    ifstream file(filename);
    if (!file.is_open()) {
        cerr << "无法打开文件: " << filename << endl;
        return false;
    }

    int n;
    if (!(file >> n) || n <= 0) {
        cerr << "无效的节点数量" << endl;
        return false;
    }

    points.resize(n);  // 直接resize避免多次push_back
    string line;
    getline(file, line); // 读取第一行剩余部分

    for (int i = 0; i < n; ++i) {
        if (!getline(file, line)) {
            cerr << "读取第 " << i + 1 << " 行失败" << endl;
            return false;
        }

        string idStr;
        double x, y, z;

        // 快速解析
        istringstream iss(line);
        if (!(iss >> idStr >> x >> y >> z)) {
            cerr << "解析第 " << i + 1 << " 行失败" << endl;
            return false;
        }

        int id = extractId(idStr);
        if (id == -1) {
            cerr << "无效的节点ID: " << idStr << endl;
            return false;
        }

        points[i].id = id;
        points[i].x = x;
        points[i].y = y;
        points[i].z = z;
        id2idx[id] = i;
    }

    file.close();
    return true;
}

// 辅助函数：读取edges.txt文件
bool readEdgesFile(const string& filename, vector<Edge>& edges,
    vector<vector<pair<int, int>>>& adj,
    const unordered_map<int, int>& id2idx,
    const vector<Point>& points) {
    ifstream file(filename);
    if (!file.is_open()) {
        cerr << "无法打开文件: " << filename << endl;
        return false;
    }

    int m;
    if (!(file >> m) || m <= 0) {
        cerr << "无效的边数量" << endl;
        return false;
    }

    edges.resize(m);  // 直接resize避免多次push_back
    string line;
    getline(file, line); // 读取第一行剩余部分

    // 预计算平方值，避免重复计算
    vector<double> x_sq(points.size()), y_sq(points.size()), z_sq(points.size());
    for (size_t i = 0; i < points.size(); ++i) {
        x_sq[i] = points[i].x * points[i].x;
        y_sq[i] = points[i].y * points[i].y;
        z_sq[i] = points[i].z * points[i].z;
    }

    for (int i = 0; i < m; ++i) {
        if (!getline(file, line)) {
            cerr << "读取第 " << i + 1 << " 行失败" << endl;
            return false;
        }

        string edgeIdStr, uStr, vStr;
        parseEdge(line, edgeIdStr, uStr, vStr);

        int uId = extractId(uStr);
        int vId = extractId(vStr);
        int edgeId = extractId(edgeIdStr);

        if (uId == -1 || vId == -1 || edgeId == -1) {
            cerr << "无效的ID格式: " << line << endl;
            return false;
        }

        auto it_u = id2idx.find(uId);
        auto it_v = id2idx.find(vId);

        if (it_u == id2idx.end() || it_v == id2idx.end()) {
            cerr << "错误：未找到节点 " << uStr << " 或 " << vStr << endl;
            return false;
        }

        int ui = it_u->second;
        int vi = it_v->second;

        // 计算边的长度（使用预计算的平方值）
        double dx = points[ui].x - points[vi].x;
        double dy = points[ui].y - points[vi].y;
        double dz = points[ui].z - points[vi].z;
        double len = sqrt(dx * dx + dy * dy + dz * dz);

        edges[i].id = edgeId;
        edges[i].u = ui;
        edges[i].v = vi;
        edges[i].len = len;
        edges[i].inv_len = 1.0 / len;  // 预计算倒数

        adj[ui].push_back({ vi, i });
        adj[vi].push_back({ ui, i });
    }

    file.close();
    return true;
}

// 辅助函数：读取sources.txt文件
bool readSourcesFile(const string& filename, vector<pair<int, double>>& sources,
    const unordered_map<int, int>& id2idx) {
    ifstream file(filename);
    if (!file.is_open()) {
        cerr << "无法打开文件: " << filename << endl;
        return false;
    }

    int ns;
    if (!(file >> ns) || ns < 0) {
        cerr << "无效的水源数量" << endl;
        return false;
    }

    sources.resize(ns);
    string line;
    getline(file, line); // 读取第一行剩余部分

    for (int i = 0; i < ns; ++i) {
        if (!getline(file, line)) {
            cerr << "读取第 " << i + 1 << " 行失败" << endl;
            return false;
        }

        istringstream iss(line);
        string sidStr;
        double Q;

        if (!(iss >> sidStr >> Q)) {
            cerr << "解析第 " << i + 1 << " 行失败" << endl;
            return false;
        }

        int sid = extractId(sidStr);
        if (sid == -1) {
            cerr << "无效的水源节点ID: " << sidStr << endl;
            return false;
        }

        auto it = id2idx.find(sid);
        if (it == id2idx.end()) {
            cerr << "错误：未找到水源节点 " << sidStr << endl;
            return false;
        }

        sources[i] = { it->second, Q };
    }

    file.close();
    return true;
}

// 辅助函数：保存节点结果到文件
void savePointsResult(const string& filename, const vector<Point>& points,
    const vector<double>& node_arrival) {
    ofstream file(filename);
    if (!file.is_open()) {
        cerr << "无法创建文件: " << filename << endl;
        return;
    }

    file << fixed << setprecision(4);
    file << "端点编号\t水流到达时刻（分钟）\n";

    char buffer[64];  // 预分配缓冲区
    for (int i = 0; i < (int)points.size(); ++i) {
        snprintf(buffer, sizeof(buffer), "P%04d\t", points[i].id);
        file << buffer;

        if (node_arrival[i] >= INF / 2) {
            file << "\n";
        }
        else {
            file << node_arrival[i] << "\n";
        }
    }

    file.close();
    cout << "节点结果已保存到: " << filename << endl;
}

// 辅助函数：保存边结果到文件
void saveEdgesResult(const string& filename, const vector<Edge>& edges) {
    ofstream file(filename);
    if (!file.is_open()) {
        cerr << "无法创建文件: " << filename << endl;
        return;
    }

    file << fixed << setprecision(4);
    file << "巷道编号\t巷道充满水时刻（分钟）\n";

    char buffer[64];  // 预分配缓冲区
    for (const auto& e : edges) {
        snprintf(buffer, sizeof(buffer), "H%04d\t", e.id);
        file << buffer;

        if (e.t_full > 0) {
            file << e.t_full << "\n";
        }
        else {
            file << "\n";
        }
    }

    file.close();
    cout << "边结果已保存到: " << filename << endl;
}