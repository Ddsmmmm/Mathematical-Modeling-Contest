#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cmath>
#include <map>
#include <sstream>
#include <limits>
#include <iomanip>

using namespace std;

// 点结构体
struct Point {
    string id;
    double x, y, z;

    Point() : x(0), y(0), z(0) {}
    Point(string id, double x, double y, double z) : id(id), x(x), y(y), z(z) {}
};

// 边结构体
struct Edge {
    string id;
    string startPointId;
    string endPointId;

    Edge() {}
    Edge(string id, string start, string end) : id(id), startPointId(start), endPointId(end) {}
};

// 计算两点间的欧几里得距离
double distance(const Point& p1, const Point& p2) {
    double dx = p1.x - p2.x;
    double dy = p1.y - p2.y;
    double dz = p1.z - p2.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
}

// 检查点是否在边上（点到线段的距离是否小于1米）
bool isPointOnEdge(const Point& p, const Point& p1, const Point& p2, double tolerance = 1.0) {
    // 计算向量
    double vx = p2.x - p1.x;
    double vy = p2.y - p1.y;
    double vz = p2.z - p1.z;

    double wx = p.x - p1.x;
    double wy = p.y - p1.y;
    double wz = p.z - p1.z;

    // 计算投影长度
    double c1 = wx * vx + wy * vy + wz * vz;
    double c2 = vx * vx + vy * vy + vz * vz;

    // 如果c2接近0，说明p1和p2是同一个点
    if (c2 < 1e-10) {
        return distance(p, p1) < tolerance;
    }

    // 计算投影参数
    double b = c1 / c2;

    // 如果投影点在线段外，计算到端点的距离
    if (b < 0) {
        return distance(p, p1) < tolerance;
    }
    else if (b > 1) {
        return distance(p, p2) < tolerance;
    }
    else {
        // 投影点在线段上，计算垂直距离
        Point projection;
        projection.x = p1.x + b * vx;
        projection.y = p1.y + b * vy;
        projection.z = p1.z + b * vz;

        return distance(p, projection) < tolerance;
    }
}

// 读取点数据
map<string, Point> readPoints(const string& filename) {
    map<string, Point> points;
    ifstream file(filename);

    if (!file.is_open()) {
        cerr << "无法打开文件: " << filename << endl;
        return points;
    }

    int count;
    file >> count;

    for (int i = 0; i < count; i++) {
        string id;
        double x, y, z;
        file >> id >> x >> y >> z;
        points[id] = Point(id, x, y, z);
    }

    file.close();
    return points;
}

// 读取边数据
vector<Edge> readEdges(const string& filename) {
    vector<Edge> edges;
    ifstream file(filename);

    if (!file.is_open()) {
        cerr << "无法打开文件: " << filename << endl;
        return edges;
    }

    int count;
    file >> count;

    for (int i = 0; i < count; i++) {
        string id, start, end;
        file >> id >> start >> end;
        edges.push_back(Edge(id, start, end));
    }

    file.close();
    return edges;
}

int main() {
    // 读取点数据和边数据
    map<string, Point> points = readPoints("points.txt");
    vector<Edge> edges = readEdges("edges.txt");

    if (points.empty() || edges.empty()) {
        cerr << "读取数据失败，请确保points.txt和edges.txt在当前目录下" << endl;
        return 1;
    }

    cout << "读取点数据: " << points.size() << " 个点" << endl;
    cout << "读取边数据: " << edges.size() << " 条边" << endl;

    // 输入突水点坐标
    double x, y, z;
    cout << "\n请输入突水点的坐标 (x y z): ";
    cin >> x >> y >> z;

    Point floodPoint("", x, y, z);

    // 精度设置
    const double EPSILON = 1.0;

    // 1. 检查是否在某个点上
    bool foundPoint = false;
    string closestPointId;
    double minDistance = numeric_limits<double>::max();

    for (const auto& pair : points) {
        double dist = distance(floodPoint, pair.second);
        if (dist < minDistance) {
            minDistance = dist;
            closestPointId = pair.first;
        }

        if (dist < EPSILON) {
            cout << "突水点位于点 " << pair.first << " 上" << endl;
            foundPoint = true;
            break;
        }
    }

    // 2. 如果不在点上，检查是否在边上
    if (!foundPoint) {
        string closestEdgePointId;
        minDistance = numeric_limits<double>::max();

        for (const auto& edge : edges) {
            if (points.find(edge.startPointId) == points.end() ||
                points.find(edge.endPointId) == points.end()) {
                continue;
            }

            const Point& p1 = points[edge.startPointId];
            const Point& p2 = points[edge.endPointId];

            // 检查是否在边上
            if (isPointOnEdge(floodPoint, p1, p2, EPSILON)) {
                // 找到较近的端点
                double dist1 = distance(floodPoint, p1);
                double dist2 = distance(floodPoint, p2);

                string nearerPointId = (dist1 < dist2) ? edge.startPointId : edge.endPointId;
                double nearerDist = min(dist1, dist2);

                if (nearerDist < minDistance) {
                    minDistance = nearerDist;
                    closestEdgePointId = nearerPointId;
                }
            }
        }

        if (!closestEdgePointId.empty()) {
            cout << "突水点位于边上，较近的端点是 " << closestEdgePointId << endl;
        }
        else {
            // 3. 都不在，输出最近的点
            cout << "突水点不在任何点或边上，最近的点是 " << closestPointId
                << "，距离为 " << fixed << setprecision(2) << minDistance << " 米" << endl;
        }
    }

    return 0;
}